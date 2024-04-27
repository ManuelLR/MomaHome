# Home Automation (things)

The heart of all home automation is [Home Assistant](https://github.com/home-assistant/home-assistant) platform.


## Home Assitant

Configuration is arranged in packages of different functionalities located in [`home_assistant-config/packages`](home_assistant-config/packages/) folder.
The configuration located in these packages are translated and linked into a usable configuration by [Home Assistant](https://github.com/home-assistant/home-assistant) through [HA_generate_real_config.sh](scripts/HA_generate_real_config.sh) script.

To check configuration syntax, you can execute the next command:
```bash
hass -c home_assistant-config/ --script check_config [--info <section_to_show>]
# or
docker run -it -v $PWD/home_automation/home_assistant/config/:/config/:ro homeassistant/home-assistant:2024.3.3 hass -c /config/ --script check_config  [--info <section_to_show>]
```
