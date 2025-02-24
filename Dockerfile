FROM python:3.9-slim
RUN pip install flask flask-mysql
COPY . .
EXPOSE 8080
CMD ["flask", "run", "--host=0.0.0.0", "--port=8080"]

#ENTYPOINT FLASK_APP=./app.py flask run
