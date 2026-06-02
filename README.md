# zChat

zChat is a cross-platform chat application aiming for smooth real-time messaging using Flutter (Dart) at its core, with platform support and enhancements provided by native modules in C++, C, Swift, and CMake. The project is structured to run on Android, iOS, Web, Linux, macOS, and Windows.

## Features

- Real-time chat support across multiple platforms
- Modular design using Dart (Flutter) for UI and shared logic
- Platform-optimized components (native code in C++, C, Swift)
- Clean, extensible codebase (see `/lib` directory)
- Firebase integration (see `firebase.json`)
- Robust project structure for maintainability and scalability

## Directory Structure

```
android/     # Android-specific code
assets/      # Assets such as images and fonts
ios/         # iOS-specific code
lib/         # Main Flutter/Dart source code
linux/       # Linux-specific code
macos/       # macOS-specific code
test/        # Test files
web/         # Web-specific implementation
windows/     # Windows-specific code
```

## How it Works

zChat leverages Flutter for its core UI and shared logic, ensuring a consistent look and feel on all platforms. Platform channels are used whenever device-native features are needed, with additional logic written in C++, C, or Swift for performance and platform integration.

The application connects to a backend (likely Firebase, based on project structure) for message storage and real-time updates.

## Setup

1. **Clone the repository**
    ```sh
    git clone https://github.com/Akshay08k/zChat.git
    cd zChat
    ```

2. **Install Flutter dependencies**
    ```sh
    flutter pub get
    ```

3. **Configure Firebase**  
    Set up Firebase for your project as described in `firebase.json` and place the necessary configuration files in the respective folders (`android/app`, `ios/Runner`, etc.).

4. **Run the app**
    - For a specific platform:
      - **Android:** `flutter run -d android`
      - **iOS:** `flutter run -d ios`
      - **Web:** `flutter run -d chrome`
      - **Windows/Mac/Linux:** `flutter run -d windows` (or respective platform)

    > Make sure you have all the required Flutter SDKs and platform tooling installed.

## Contribution

Contributions are welcome! To get started:

1. Fork this repository.
2. Create a new branch: `git checkout -b my-feature`
3. Make your changes.
4. Commit and push: `git commit -am 'Add some feature'` and `git push origin my-feature`
5. Create a Pull Request describing your changes.

Please write clear, descriptive commit messages and update/add relevant documentation and tests.

## License

This project is open-sourced for learning and collaboration purposes. For now, there is **no explicit license file**, so all rights are reserved to the owner: [Akshay08k](https://github.com/Akshay08k/).

If you wish to use this work beyond open collaboration or would like to see a specific license (MIT, Apache-2.0, etc.), please open an issue or contact the maintainer.

---

Made with ❤️ using Flutter, Dart, and cross-platform tech.
