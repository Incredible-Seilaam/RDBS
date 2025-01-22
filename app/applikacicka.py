# from sqlalchemy import create_engine, Column, Integer, String, ForeignKey, func
# from sqlalchemy.orm import declarative_base, sessionmaker, relationship

# Base = declarative_base()

# class User(Base):
#     __tablename__ = 'Users'
#     id = Column(Integer, primary_key=True)
#     username = Column(String)
#     email = Column(String)

# class Song(Base):
#     __tablename__ = 'Songs'
#     id = Column(Integer, primary_key=True)
#     title = Column(String)
#     duration = Column(Integer)

# engine = create_engine('postgresql://natal:Aurhzuar321@db:5432/music_library_v2')
# Session = sessionmaker(bind=engine)
# session = Session()

# avg_duration = session.query(func.avg(Song.duration)).scalar()
# print(f"Prumerna delka pisni: {avg_duration} sekund")