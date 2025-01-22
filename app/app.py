from flask import Flask, render_template, request, redirect, url_for
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)

app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://postgres:postgres@postgres_db:5432/music_library_v2'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

class User(db.Model):
    __tablename__ = 'Users'
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String)
    email = db.Column(db.String)

class Song(db.Model):
    __tablename__ = 'Songs'
    id = db.Column( db.Integer, primary_key=True)
    title =  db.Column( db.String)
    duration =  db.Column( db.Integer)

@app.route('/')
def avg_song_duration():
    avg_duration = db.session.query(db.func.avg(Song.duration)).scalar()
    if avg_duration is not None:
        avg_duration = round(float(avg_duration), 2)  # zaokrouhlení na 2 desetinná místa
    return render_template('avg_duration.html', average_duration=avg_duration)
    # return f"Prumerna delka pisni: {avg_duration} sekund"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)