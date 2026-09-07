"""Jinja2 filters that turn the compact policy/list definitions in
group_vars into UniFi Network Integration API bodies, and compare them
against what the API returns.

Schema reference: developer.ui.com/network (Firewall Policies, Firewall
Zones, Traffic Matching Lists).
"""

from __future__ import annotations

import json

from ansible.errors import AnsibleFilterError


# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

def _lookup(mapping, name, kind):
    try:
        return mapping[name]
    except KeyError:
        raise AnsibleFilterError(f"unifi_firewall: unknown {kind} '{name}' (known: {sorted(mapping)})")


def _port_items(ports):
    items = []
    for p in ports:
        s = str(p)
        if "-" in s:
            start, stop = s.split("-", 1)
            items.append({"type": "PORT_NUMBER_RANGE", "startPort": int(start), "endPort": int(stop)})
        else:
            items.append({"type": "PORT_NUMBER", "value": int(s)})
    return items


def _ip_items(addresses):
    items = []
    for a in addresses:
        s = str(a)
        if "/" in s:
            items.append({"type": "SUBNET", "value": s})
        elif "-" in s:
            start, stop = s.split("-", 1)
            items.append({"type": "IP_ADDRESS_RANGE", "start": start, "stop": stop})
        else:
            items.append({"type": "IP_ADDRESS", "value": s})
    return items


def _port_filter(side, list_map):
    opposite = bool(side.get("match_opposite_ports", False))
    if side.get("port_list"):
        return {
            "type": "TRAFFIC_MATCHING_LIST",
            "trafficMatchingListId": _lookup(list_map, side["port_list"], "traffic matching list"),
            "matchOpposite": opposite,
        }
    return {"type": "PORTS", "items": _port_items(side["ports"]), "matchOpposite": opposite}


def _endpoint(side, zone_map, list_map, network_map):
    out = {"zoneId": _lookup(zone_map, side["zone"], "zone")}
    has_ports = bool(side.get("port_list") or side.get("ports"))
    opposite = bool(side.get("match_opposite", False))
    tf = None

    if side.get("ip_list") or side.get("ips"):
        if side.get("ip_list"):
            ipf = {
                "type": "TRAFFIC_MATCHING_LIST",
                "trafficMatchingListId": _lookup(list_map, side["ip_list"], "traffic matching list"),
                "matchOpposite": opposite,
            }
        else:
            ipf = {"type": "IP_ADDRESSES", "items": _ip_items(side["ips"]), "matchOpposite": opposite}
        tf = {"type": "IP_ADDRESS", "ipAddressFilter": ipf}
        if has_ports:
            tf["portFilter"] = _port_filter(side, list_map)
    elif side.get("networks"):
        tf = {
            "type": "NETWORK",
            "networkFilter": {
                "networkIds": [_lookup(network_map, n, "network") for n in side["networks"]],
                "matchOpposite": opposite,
            },
        }
        if has_ports:
            tf["portFilter"] = _port_filter(side, list_map)
    elif side.get("macs"):
        tf = {"type": "MAC_ADDRESS", "macAddressFilter": {"macAddresses": list(side["macs"])}}
    elif has_ports:
        tf = {"type": "PORT", "portFilter": _port_filter(side, list_map)}

    if tf is not None:
        out["trafficFilter"] = tf
    return out


def _normalise(value):
    """Drop null keys and sort scalar lists so API responses compare equal
    to the bodies we generate."""
    if isinstance(value, dict):
        return {k: _normalise(v) for k, v in sorted(value.items()) if v is not None}
    if isinstance(value, list):
        norm = [_normalise(v) for v in value]
        if all(not isinstance(v, (dict, list)) for v in norm):
            return sorted(norm, key=str)
        return sorted(norm, key=lambda v: json.dumps(v, sort_keys=True))
    return value


# ---------------------------------------------------------------------------
# firewall policies
# ---------------------------------------------------------------------------

_POLICY_COMPARE_KEYS = (
    "name", "enabled", "action", "ipProtocolScope", "loggingEnabled",
    "source", "destination", "connectionStateFilter", "description", "schedule",
)


def unifi_policy_body(policy, zone_map, list_map, network_map):
    action_type = str(policy["action"]).upper()
    action = {"type": action_type}
    if action_type == "ALLOW":
        action["allowReturnTraffic"] = bool(policy.get("allow_return_traffic", True))

    scope = {"ipVersion": str(policy.get("ip_version", "IPV4")).upper()}
    proto = policy.get("protocol")
    if proto and str(proto).lower() != "all":
        scope["protocolFilter"] = {
            "type": "NAMED_PROTOCOL",
            "protocol": {"name": str(proto).lower()},
            "matchOpposite": bool(policy.get("match_opposite_protocol", False)),
        }

    body = {
        "name": policy["name"],
        "enabled": bool(policy.get("enabled", True)),
        "action": action,
        "ipProtocolScope": scope,
        "loggingEnabled": bool(policy.get("logging", False)),
        "source": _endpoint(policy["source"], zone_map, list_map, network_map),
        "destination": _endpoint(policy["destination"], zone_map, list_map, network_map),
    }
    if policy.get("connection_state"):
        body["connectionStateFilter"] = [str(s).upper() for s in policy["connection_state"]]
    if policy.get("description"):
        body["description"] = policy["description"]
    if policy.get("schedule"):
        body["schedule"] = policy["schedule"]
    return body


def unifi_policy_key(policy_or_body):
    """Composite identity: name + source zone + destination zone."""
    return "||".join([
        policy_or_body["name"],
        policy_or_body["source"]["zoneId"],
        policy_or_body["destination"]["zoneId"],
    ])


def unifi_policy_changed(existing, body):
    left = _normalise({k: existing.get(k) for k in _POLICY_COMPARE_KEYS})
    right = _normalise({k: body.get(k) for k in _POLICY_COMPARE_KEYS})
    return left != right


def unifi_policy_ordering(existing_ordering, managed_ids):
    """Managed policies first, in file order, then any unmanaged
    user-defined policies in their current relative order."""
    current = existing_ordering.get("orderedFirewallPolicyIds", existing_ordering) or {}
    before = list(current.get("beforeSystemDefined") or [])
    after = list(current.get("afterSystemDefined") or [])
    managed = [m for m in managed_ids if m]
    return {
        "orderedFirewallPolicyIds": {
            "beforeSystemDefined": managed + [i for i in before if i not in managed],
            "afterSystemDefined": [i for i in after if i not in managed],
        }
    }


# ---------------------------------------------------------------------------
# traffic matching lists
# ---------------------------------------------------------------------------

def unifi_tml_body(tml):
    kind = str(tml["type"]).upper()
    if kind == "PORTS":
        items = _port_items(tml["items"])
    elif kind in ("IPV4_ADDRESSES", "IPV6_ADDRESSES"):
        items = _ip_items(tml["items"])
    else:
        raise AnsibleFilterError(f"unifi_firewall: unsupported traffic matching list type '{kind}'")
    return {"name": tml["name"], "type": kind, "items": items}


def unifi_tml_changed(existing, body):
    keys = ("name", "type", "items")
    return _normalise({k: existing.get(k) for k in keys}) != _normalise({k: body.get(k) for k in keys})


class FilterModule:
    def filters(self):
        return {
            "unifi_policy_body": unifi_policy_body,
            "unifi_policy_key": unifi_policy_key,
            "unifi_policy_changed": unifi_policy_changed,
            "unifi_policy_ordering": unifi_policy_ordering,
            "unifi_tml_body": unifi_tml_body,
            "unifi_tml_changed": unifi_tml_changed,
        }
