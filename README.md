# Python Compiler with Flutter

A modern, cross-platform Python code editor and compiler built with Flutter and Python Flask. This application provides a beautiful, responsive interface for writing, executing, and managing Python code across multiple platforms.

## 🚀 Features

### Core Functionality

- **Real-time Python Code Execution**: Write and execute Python code instantly
- **Syntax Highlighting**: Beautiful code highlighting powered by `flutter_highlight`
- **Cross-Platform Support**: Runs on iOS, Android, Web, Windows, macOS, and Linux
- **Responsive Design**: Optimized UI for both mobile and desktop experiences

### User Experience

- **🌓 Dark/Light Theme Support**: Toggle between dark and light modes
- **📝 Code Editor**: Feature-rich code input with proper formatting
- **🔍 Find & Replace**: Advanced text search and replacement functionality
- **📊 Execution Output**: Clear display of code results and error messages
- **📚 History Management**: Keep track of executed code and clear when needed

### Technical Features

- **Secure Code Execution**: Python code runs in isolated environment with timeout protection
- **RESTful API**: Clean HTTP communication between Flutter frontend and Python backend
- **State Management**: Efficient state handling using Provider pattern
- **Error Handling**: Comprehensive error reporting and timeout management

## 🏗️ Architecture

```
┌─────────────────┐    HTTP/REST    ┌─────────────────┐
│   Flutter App   │ ───────────────→ │  Python Flask   │
│   (Frontend)    │                 │   (Backend)     │
│                 │ ←─────────────── │                 │
│ - UI Components │    JSON         │ - Code Executor │
│ - State Mgmt    │                 │ - Error Handler │
│ - HTTP Client   │                 │ - CORS Support  │
└─────────────────┘                 └─────────────────┘
```

## 🛠️ Technology Stack

### Frontend (Flutter)

- **Flutter SDK**: Cross-platform UI framework
- **Dart**: Programming language
- **Provider**: State management
- **HTTP**: API communication
- **Flutter Highlight**: Syntax highlighting
- **Material Design**: UI components

### Backend (Python)

- **Flask**: Lightweight web framework
- **Flask-CORS**: Cross-origin resource sharing
- **Subprocess**: Secure code execution

## 📦 Installation

### Prerequisites

- Flutter SDK (>=3.4.0)
- Python 3.7+
- Git

### Backend Setup

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd python_compiler_with_flutter
   ```

2. **Set up Python virtual environment**

   ```bash
   python -m venv venv
   ```

3. **Activate virtual environment**

   ```bash
   # Windows
   venv\Scripts\activate

   # macOS/Linux
   source venv/bin/activate
   ```

4. **Install Python dependencies**

   ```bash
   pip install -r requirements.txt
   ```

5. **Start the Flask backend**

   ```bash
   python lib/backend/app.py
   ```

   The backend will be available at `http://localhost:5000`

### Frontend Setup

1. **Install Flutter dependencies**

   ```bash
   flutter pub get
   ```

2. **Run the Flutter app**

   ```bash
   # For development
   flutter run

   # For specific platform
   flutter run -d chrome    # Web
   flutter run -d windows   # Windows
   flutter run -d macos     # macOS
   ```

## 🖥️ Usage

### Running Python Code

1. **Start the backend server** (see Backend Setup)
2. **Launch the Flutter app**
3. **Write Python code** in the code editor
4. **Click "Run Code"** to execute
5. **View output** in the results panel

### Interface Guide

- **Code Editor**: Main input area with syntax highlighting
- **Run Code Button**: Executes the current code
- **Clear Button**: Clears the code editor
- **Theme Toggle**: Switch between dark and light modes (top-right)
- **Clear History**: Remove execution history (top-right)
- **Output Panel**: Displays execution results and errors

### Example Code

```python
# Simple example
print("Hello, World!")

# More complex example
import math

def calculate_circle_area(radius):
    return math.pi * radius ** 2

radius = 5
area = calculate_circle_area(radius)
print(f"Circle area with radius {radius}: {area:.2f}")
```

## 🔧 Configuration

### Backend Configuration

The Flask backend can be configured in `lib/backend/app.py`:

- **Host**: Default `0.0.0.0` (all interfaces)
- **Port**: Default `5000`
- **Timeout**: Code execution timeout set to 10 seconds

### Frontend Configuration

Key configurations in the Flutter app:

- **API Endpoint**: Configure in `lib/services/python_execution_service.dart`
- **Theme Settings**: Managed in `lib/providers/provider.dart`
```

## 🧪 Development

```

### Key Components

- **PythonCompilerProvider**: Main state management
- **CodeInputWidget**: Code editor with syntax highlighting
- **ExecutionOutputWidget**: Results display
- **PythonExecutionService**: API communication

### Adding Features

1. **New UI Components**: Add to `lib/widgets/`
2. **API Endpoints**: Extend `lib/backend/app.py`
3. **State Management**: Update `lib/providers/provider.dart`
4. **Models**: Define in `lib/models/`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

### Common Issues

- **Backend not starting**: Check Python installation and dependencies
- **CORS errors**: Ensure Flask-CORS is properly configured
- **Code execution timeout**: Increase timeout in backend configuration
- **UI not responsive**: Check Flutter version and run `flutter doctor`

### Getting Help

- Check the Issues tab for known problems
- Create a new issue with detailed problem description
- Include system information and error logs

## 🙏 Acknowledgments

- Flutter team for the amazing cross-platform framework
- Python community for Flask and related libraries
- Contributors to the open-source packages used in this project

---
