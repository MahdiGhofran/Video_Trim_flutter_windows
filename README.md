# Flutter Windows Video Trimming Page

A video trimming page built with Flutter for Windows. This widget provides a simple and effective way to trim videos using FFmpeg, making it ideal for projects where no dedicated Flutter package exists for video trimming on Windows.

## Overview

This project demonstrates how to:
- Load and play a video file using the `video_player` package.
- Select a trimming range using a `RangeSlider`.
- Trim the video using FFmpeg via the `process_run` package.
- Handle FFmpeg path detection and allow manual configuration if needed.

## Features

- **Video Playback:** Preview the video using the built-in player.
- **Range Selection:** Adjust the start and end points of the trim range.
- **FFmpeg Integration:** Automatically detect FFmpeg in common locations; prompt for manual path if not found.
- **Responsive UI:** Real-time updates on the video playback and trimming progress.

## Prerequisites

Before integrating this code, ensure you have the following:
- **Flutter SDK:** Installed and set up for Windows development.
- **FFmpeg:** Installed on your system. If FFmpeg is not in your system's PATH, you can manually specify its location via the settings button in the app.
- **Dependencies:** The following Flutter packages should be added to your `pubspec.yaml`:
  - `video_player`
  - `flutter_bloc`
  - `process_run`
  - `path`

## Installation

1. **Clone or Download the Repository:**
   ```bash
   git clone https://github.com/yourusername/your-repo-name.git
   ```
2. **Add Dependencies:**

   In your project's `pubspec.yaml`, add:
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     video_player: ^2.0.0
     flutter_bloc: ^8.0.0
     process_run: ^0.12.0
     path: ^1.8.0
   ```
   Then run:
   ```bash
   flutter pub get
   ```

## Integration

To integrate the video trimming page into your project, follow these steps:

1. **Copy the Code:**
   - Add the `TrimPage` widget file to your project (e.g., in a folder named `pages` or `widgets`).

2. **Bloc Integration (Optional):**
   - The code uses the `flutter_bloc` package for event handling. Ensure you have set up your Bloc (in this example, an `AppBloc` is used with an event called `TrimCompleted`).
   - If you are not using Bloc, you can remove or adjust the Bloc parts (i.e., the context.read<AppBloc>().add(TrimCompleted(outputPath)); line).

3. **FFmpeg Configuration:**
   - The widget tries to auto-detect FFmpeg from common paths. If not found, a dialog will prompt the user to input the FFmpeg executable path.
   - Make sure FFmpeg is installed on your system. You can download it from [ffmpeg.org](https://ffmpeg.org/download.html).

## Usage

To use the `TrimPage` widget, navigate to it with a valid video file path. For example:

```dart
import 'package:flutter/material.dart';
import 'path_to_your_trim_page/trim_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Replace with the path to your video file
  final String videoPath = 'C:\\path\\to\\your\\video.mp4';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Trimmer',
      home: TrimPage(videoPath),
    );
  }
}
```

### How It Works

- **Video Loading:**  
  The `TrimPage` initializes a `VideoPlayerController` with the provided video file and listens for playback changes.

- **Range Slider:**  
  A `RangeSlider` is used to select the start and end points of the video. The selected values update the UI and are used to define the trim range.

- **Trimming Process:**  
  When the user taps the "Save Trimmed Video" button, the app verifies FFmpeg availability. It then constructs a command to trim the video based on the selected range and executes it using the `process_run` package. The trimmed video is saved to the system's temporary directory, and a confirmation is provided via a SnackBar.

- **FFmpeg Path Dialog:**  
  If FFmpeg is not detected in the usual locations, the user is prompted to provide the path manually.

## Troubleshooting

- **FFmpeg Not Found:**  
  If you receive an error regarding FFmpeg, ensure that:
  - FFmpeg is installed.
  - FFmpeg is added to your system's PATH, or use the settings button to manually input its path.

- **Video Loading Issues:**  
  Verify that the provided video path is correct and that the video file is accessible.

## License

Include your license information here (e.g., MIT License).

## Contributing

Feel free to fork the repository and submit pull requests. For major changes, please open an issue first to discuss what you would like to change.

---

Happy coding!
```

