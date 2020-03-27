# TfL Planner

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/4b580313bbb349de8a7bfeda9b89f63e)](https://www.codacy.com?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=g30r93g/Tube-Planner&amp;utm_campaign=Badge_Grade)
[![GitHub issues](https://img.shields.io/github/issues/Naereen/StrapDown.js.svg)](https://github.com/g30r93g/TfL-Planner/issues)
[![Swift 5.1](https://img.shields.io/badge/Swift-5.1-orange.svg)](https://developer.apple.com/swift)
[![iOS Platform](https://img.shields.io/badge/platform-iOS-green.svg)](https://developer.apple.com/)

A Level Computer Science Non-Examined Assessment

Copyright © George Nick Gorzynski (g30r93g) 2019

## Description

A routing app that runs on iOS devices for London's TfL tube and rail network. Pathfinding is performed on device and will return multiple routes that meet a given filter, such as number of changes, route convenience, fare cost, line status, travelcard balance and time planning. These routes will then be shown on the Tube Map which will dynamically change based on the appropriate routes. Walking directions will be shown on a geographical map. Pathfinding can take stations, street addresses and Points of Interests, as well as favourite locations which the user can set to start a route to from their current location. Travelcard journey history and balance information will be available to the user via their Oyster account and current and future line status will also be viewable.

## Purpose

This is to version control my A Level project and show evidence of working on my project.

## Features

*   Dijkstra and A* Routing Algorithm (Manhattan Heuristic)
*   Yen's K-Shortest Paths Algorithm
*   Route Displayed on Interactive Tube Map with Overview during route selection
*   Walking Directions when internet connection is available
*   Step by Step Routing Instructions
*   Indicates which side doors open on
*   Online and Offline Capabilities
*   Current Status and Fare Estimates from TfL Unified API
*   Oyster and Contactless Journey History and Balance from TfL Customer API
*   Time Planning

## Authors

George Nick Gorzynski ([@g30r93g](https://github.com/g30r93g))

## Acknowledgements

*   Yasin Abbas ([@yabbas](https://github.com/yabbas)) - Teacher
*   Paul Hudson ([@twostraws](https://github.com/twostraws)) - [Hacking With Swift](https://www.hackingwithswift.com/)
*   Ray Wenderlich ([@raywenderlich](https://github.com/raywenderlich)) - [RayWenderlich](https://www.raywenderlich.com/)
*   Greg Fleming - [Railway.otf](https://www.fontspace.com/greg-fleming/railway)
*   TfL - [Open Data](https://api.tfl.gov.uk)
*   Wikipedia - [TfL Roundel](https://en.m.wikipedia.org/wiki/File:Tfl_white_no-text.svg), [Yen's KSP](https://en.wikipedia.org/wiki/Yen%27s_algorithm)

## License

There is no such license for this software. Therefore the contents of this repository written by myself is subject to copyright and no aspects may be used without written permission. However, all software, content, illustrations or any copyrighted material used in this project is subject to the license between myself and the author of the copyrighted material. This project does not intend to infringe any copyrights and if it does, I apologise first and foremost, and am happy to alter, retract and/or delete the infringing material. 
