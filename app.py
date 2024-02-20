import os
from flask import Flask, request, jsonify, render_template
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
app = Flask(__name__)
user = os.getenv('MYSQL_USER')
password = os.getenv('MYSQL_PASSWORD')
hostname = os.getenv('MYSQL_SERVICE_HOST', 'mysql-service')
port = os.getenv('MYSQL_SERVICE_PORT', '3306')
database_name = os.getenv('MYSQL_DATABASE')
app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = f'mysql+pymysql://{user}:{password}@{hostname}:{port}/{database_name}'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

class WorkoutTypes(db.Model):
    __tablename__ = 'workout_types'
    __table_args__ = {'mysql_engine': 'InnoDB', 'mysql_charset': 'utf8'}
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), unique=True, nullable=False)

class Workouts(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    __tablename__ = 'workouts'
    __table_args__ = {'mysql_engine': 'InnoDB', 'mysql_charset': 'utf8'}
    workout_type_id = db.Column(db.Integer, db.ForeignKey('workout_types.id'), nullable=False)
    duration = db.Column(db.Float, nullable=False)  # Duration in minutes
    intensity = db.Column(db.String(50))
    date = db.Column(db.DateTime, default=datetime.utcnow)

class Biometrics(db.Model):
    __tablename__ = 'biometrics'
    __table_args__ = {'mysql_engine': 'InnoDB', 'mysql_charset': 'utf8'}
    id = db.Column(db.Integer, primary_key=True)
    heart_rate = db.Column(db.Integer)
    calories_burned = db.Column(db.Integer)
    workout_id = db.Column(db.Integer, db.ForeignKey('workouts.id'), nullable=False)
    date = db.Column(db.DateTime, default=datetime.utcnow)

@app.route('/workout-types', methods=['POST'])
def add_workout_type():
    data = request.json
    new_type = WorkoutTypes(name=data['name'])
    db.session.add(new_type)
    db.session.commit()
    return jsonify({'message': 'Workout type added'}), 201

@app.route('/workouts', methods=['POST'])
def log_workout():
    data = request.json
    workout = Workouts(
        workout_type_id=data['workout_type_id'],
        duration=data['duration'],
        intensity=data['intensity']
    )
    db.session.add(workout)
    db.session.commit()
    return jsonify({'message': 'Workout logged'}), 201

@app.route('/biometrics', methods=['POST'])
def log_biometrics():
    data = request.json
    biometric = Biometrics(
        heart_rate=data['heart_rate'],
        calories_burned=data['calories_burned'],
        workout_id=data['workout_id']
    )
    db.session.add(biometric)
    db.session.commit()
    return jsonify({'message': 'Biometrics logged'}), 201

@app.route('/data/workouts')
def get_workout_data():
    workouts = Workouts.query.all()
    dates = [workout.date.strftime('%Y-%m-%d') for workout in workouts]
    durations = [workout.duration for workout in workouts]
    return jsonify(dates=dates, durations=durations)

@app.route('/data/biometrics')
def get_biometric_data():
    biometrics = Biometrics.query.all()
    dates = [biometric.date.strftime('%Y-%m-%d') for biometric in biometrics]
    heart_rates = [biometric.heart_rate for biometric in biometrics]
    return jsonify(dates=dates, heart_rates=heart_rates)

@app.route('/')
def charts():
    db.create_all()
    return render_template('chart.html')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
