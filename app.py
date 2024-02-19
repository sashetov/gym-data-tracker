from flask import Flask
import hashlib
import os

app = Flask(__name__)

# Endpoint to generate CPU load by calculating hash
@app.route('/cpu')
def cpu_load():
    for _ in range(1000000):
        hashlib.sha256(os.urandom(1024)).hexdigest()
    return 'CPU load generated'

# Endpoint to generate Memory load by allocating memory
@app.route('/memory')
def memory_load():
    some_large_var = ' ' * 10**7  # Allocate a string with 10 million spaces
    return 'Memory load generated'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
