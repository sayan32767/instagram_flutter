import 'package:flutter/material.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

// NOT IN USE CURRENTLY. This is for detecting when the ReelsScreen is covered by another screen (e.g., when navigating to a profile or comments) so that we can pause the video. We can also use it to detect when we come back to the ReelsScreen and resume the video.
