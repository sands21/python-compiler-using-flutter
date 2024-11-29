import sys
import subprocess
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)


@app.route('/execute', methods=['POST'])
def execute_python_code():
    try:
        # Get code from request
        data = request.get_json()
        code = data.get('code', '')

        # Execute Python code
        result = subprocess.run(
            [sys.executable, '-c', code],
            capture_output=True,
            text=True,
            timeout=10
        )

        return jsonify({
            'success': result.returncode == 0,
            'output': result.stdout or result.stderr
        })

    except subprocess.TimeoutExpired:
        return jsonify({
            'success': False,
            'output': 'Code execution timed out'
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'output': str(e)
        })


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
