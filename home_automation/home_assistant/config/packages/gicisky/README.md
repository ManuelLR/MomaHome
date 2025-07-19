# Gicisky BLE Label Integration

This package contains configuration for the Gicisky BLE Label integration in Home Assistant.

## What is Gicisky?

Gicisky is a BLE (Bluetooth Low Energy) electronic label system that can display text, images, and other content. This integration allows you to control Gicisky labels from Home Assistant.

## Setup

1. The integration is automatically installed via the Dockerfile
2. The integration is enabled in the main configuration.yaml
3. You need to discover and pair your Gicisky devices
4. Replace `YOUR_GICISKY_DEVICE_ID_HERE` in the example configuration with your actual device ID

## Features

- Display text with custom fonts, colors, and positioning
- Display images
- Update content automatically based on Home Assistant entities
- Support for different label sizes (2.1", 4.2", 7.5")

## Example Configurations

### Date Display
The `example_label.yaml` file shows how to display the current date and day of the week on a Gicisky label.

### Weather Display
You can create automations to display weather information, calendar events, or any other Home Assistant data.

## Device Discovery

To find your Gicisky device ID:
1. Enable the integration in Home Assistant
2. Check the Home Assistant logs for discovered devices
3. Use the device ID in your automation configurations

## Documentation

For more information, visit the [official repository](https://github.com/eigger/hass-gicisky).

## Supported Label Models

- 2.1" labels
- 4.2" labels  
- 7.5" labels

Each model has different resolution and capabilities. Check the examples in the official repository for model-specific configurations.