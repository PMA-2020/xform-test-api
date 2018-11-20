"""Web application for XFormTest

http://xform-test.pma2020.org
http://xform-test-docs.pma2020.org
"""
import json
from glob import glob
import os
import sys

from flask import Flask, jsonify, request
from flask_cors import CORS
from werkzeug.utils import secure_filename

# noinspection PyProtectedMember
from static_methods import _return_failing_result, _run_process
from config import HEROKU_ERR_EVERY_TIME, XFORM_TEST_EXECUTABLE, LOGGING_ON, \
    TEMP_DIR, IS_WINDOWS

app = Flask(__name__)
CORS(app)
basedir = os.path.abspath(os.path.dirname(__file__))
path_char = '\\' if IS_WINDOWS else '/'


@app.route('/')
@app.route('/<string:filename>')
@app.route('/xform_test/<string:filename>')
def xform_test(filename=None):
    """Runs XFormTest CLI."""
    if not filename or filename == 'favicon.ico':
        # Not sure why, but when running in dev env in Pycharm, loading '/'
        # with no query args renderrs param as 'favicon.ico'. -jef 2018/11/20
        return jsonify({
            'error': 'No file was passed.'
        })
    try:
        if filename.endswith('.xls') or filename.endswith('.xlsx'):
            xml = filename.replace('.xlsx', '.xml').replace('.xls', '.xml')
            command = 'xls2xform ' + TEMP_DIR + path_char + filename + ' ' + \
                      TEMP_DIR + path_char + xml
            stdout, stderr = _run_process(command)
            stderr = '' if stderr == HEROKU_ERR_EVERY_TIME else stderr
            # err when converting to xml
            if stderr:
                presentable_err = stderr
                if 'Traceback' in stderr:
                    presentable_err_lines = []
                    lines = stderr.split('\n')
                    for i in range(len(lines)):
                        line = lines[len(lines) - i - 1].strip()
                        if not line.startswith('File'):
                            presentable_err_lines = [line] + \
                                                    presentable_err_lines
                        else:
                            break
                    presentable_err = '\n'.join(presentable_err_lines)
                return _return_failing_result(presentable_err, stdout)
        else:
            xml = filename

        command = 'java -jar ' + XFORM_TEST_EXECUTABLE + ' ' \
                  + TEMP_DIR + path_char + xml
        stdout, stderr = _run_process(command)
        stderr = '' if stderr == HEROKU_ERR_EVERY_TIME else stderr
        for file in glob('temp/*'):
            os.remove(file)

        # err when running xform-test
        if stderr:
            return _return_failing_result(stderr, stdout)

        # passing result
        result = json.loads(stdout)
        success = result['successMsg']
        warnings = result['warningsMsg']

        return jsonify({
            'success': success,
            'warnings': warnings,
            'error': stderr if LOGGING_ON else ''
        })
    # unexpected err
    except Exception as err:
        print(str(err), file=sys.stderr)
        return jsonify({'error': str(err)})


@app.route('/upload', methods=['POST'])
def upload():
    """Upload"""
    try:
        files = request.files
        if len(files) > 1:
            return jsonify({
                'error': 'Only one file can be uploaded at a time.'
            })
        original_filename = [k for k, v in files.items()][0]
        file = files[original_filename]
        filename = secure_filename(original_filename)

        upload_folder = basedir + path_char + TEMP_DIR
        file_path = os.path.join(upload_folder, filename)

        if os.path.exists(file_path):
            os.remove(file_path)

        try:
            file.save(file_path)
        except FileNotFoundError:
            os.mkdir(upload_folder)
            file.save(file_path)

        return xform_test(filename=filename)
    except Exception as err:
        return jsonify({
            'error': 'An unexpected error occurred:\n\n' + str(err)
        })


if __name__ == '__main__':
    app.run(debug=True, port=8080)
