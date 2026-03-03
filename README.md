# MondSicht

View the moon

## Introduction

This app shows the moon as it is visible in the sky, at the current time and location.

It also provides viewing information.

## User interface

The app has a main screen. The top, square part of the screen features a visual of the moon's current
appearance, taken from an actual photograph of the moon's earth-facing side, and simulating the current
phase and illumination, and rotation cause by the observer's position on the Earth.

The moons basic image is located in the assets folder: images/full_moon.jpg
Image credit: Luc Viatour. https://lucnix.be/

The lower part displays additional information about the moon and its position in the sky:

* The current phase of the moon as a name
* The current illumination of the moon in percent
* The current position of the moon in degrees for azimuth and elevation
* The time of next moon rise
* The time of next moon set
* The time of next new moon
* The time of next full moon

All times are in the time zone set on the device. For times that are the next day, a "+1" is 
appended to the time.

### Theming

The app supports uses a dark theme.

### Responsive design

The app uses responsive design to partition the screen:
* in protract mode the app uses a single column layout with the moon's image on top.
* in Landscape mode tha app uses a two-column layout with the moon's image on the left and the
other information on the right.

## Permissions

The app requires access to the device's precise location. It will request this permission at startup 
if it has not already been granted.
In case the permission is not granted, the app will not work and show a message to the effect.


## Architecture

The app uses clean architecture implemented using Blocs and/or Cubits for the business logic
as well as suitable repositories to store and retrieve settings and recent calculations.

## Implementation

The implementation uses a folder structure representing the architecture, and in line with
clean architecture principles: repositories, models, blocs, entities and presentation
live in their proper folders. Presentation elements are suitably distributed into folders
representing categories like display, buttons, layout elements, etc.

### Astronomical calculations

Calculations may be performed in standard double precision floating point.

### Rendering

The moon's image should be rendered by drawing the illuminated part of the moon using and alpha
overlay, and then rotating the resulting image to match parallax caused by the observer's position.
Libration and distance of the moon is currently not considerd for rendering.

### Update frequency

Location, calculations and rendering are updated when the observer's position becomes first available, 
and the at regular intervals on 1 minute.

No local data needs to be stored, as all information can be quickly calculated.

## Target platforms and technology

The app shall be implemented in Flutter, targeting all common platforms: Android, iOS, macOS, Windows,
Web and optionally Linux.
