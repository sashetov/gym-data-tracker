from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://user:password@mysql-service/db_name'
db = SQLAlchemy(app)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
