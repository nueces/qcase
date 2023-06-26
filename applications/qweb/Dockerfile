FROM python:3.10-slim

COPY ./src /app
COPY ./requirements.txt /app/requirements.txt

WORKDIR /app
RUN pip install --no-cache-dir --upgrade -r /app/requirements.txt

# See all the configuration in the config.py file
CMD ["gunicorn", "--conf", "config.py", "app"]
