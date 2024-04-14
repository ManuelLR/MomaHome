# Monitoring

Welcome to the Monitoring section!

## Basis

I decided to use [Netdata](https://github.com/netdata/netdata) as the central component.
This tool is easy to maintain and with a ton of functionality already included.

### Architecture

TODO: Add diagram

I'm going to use two Netdata Agents, one acting as parent (in my server) and other in the OpenWrt router acting as a child with no functionality, only forwarding the data to the parent.


## Netdata parent (aka, on the server)

