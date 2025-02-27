from flask import Flask, render_template, Response
import os
import random
import pymysql
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

# Database connection parameters
# DB_HOST = os.getenv("MYSQL_HOST", "db") # deflt was localhost
# DB_USER = os.getenv("MYSQL_USER", "user")
# DB_PASSWORD = os.getenv("MYSQL_PASSWORD", "password")
# DB_NAME = os.getenv("MYSQL_DATABASE", "mydatabase")
# DB_PORT = int(os.getenv("MYSQL_PORT", 3306)) # maybe 3307? nah according to last line of this code, it gotta be the port in the container (3306)
DB_HOST = os.getenv("MYSQL_HOST", "db")  # Matches the service name in docker-compose.yml
DB_PORT = int(os.getenv("MYSQL_PORT", 3306))  # Internal MySQL port
DB_USER = os.getenv("MYSQL_USER", "user")
DB_PASSWORD = os.getenv("MYSQL_PASSWORD", "password")
DB_NAME = os.getenv("MYSQL_DATABASE", "mydatabase")

# PROMETHEUS metric: Visitor Counter
visitor_counter = Counter("space_capybara_visitors", "Total visitors to the website")

def get_image_url():
    # Fetch a random image URL from the database.
    connection = pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        port=DB_PORT
    )
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT imagescol FROM images ORDER BY RAND() LIMIT 1;")
            result = cursor.fetchone()
            # print(f"////////////result url: {result} ///////////////")
            return result[0] if result else None
    finally:
        connection.close()



# # list of capy images
# images = [
#     "https://api.capy.lol/v1/capybara"]

def get_visitors_count(): # if you want to see the visitors count on displayed on the site, then you're another visitor
    connection2 = pymysql.connect( # connect to db
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        port=DB_PORT
    )
    try:
        with connection2.cursor() as cursor2:
            # Increment the counter and retrieve the new value
            cursor2.execute("UPDATE visitor_counter SET count = count + 1") # so +1 here
            connection2.commit()
            cursor2.execute("SELECT count FROM visitor_counter LIMIT 1") # select the first line in visitor_counter table, the count column (which all there really is)
            result = cursor2.fetchone()
            # PROMETHEUS: Increment the Prometheus counter (Persists across requests)
            visitor_counter.inc()

            return result[0] if result else 0 # returns an int, if there's no value in table (in whatever cursor points to) then return 0 visitors
    finally:
        connection2.close() # close the connection

# @app.route("/")
# def index():
#     url = get_image_url()
#     if not url:
#         url = "https://via.placeholder.com/150?text=No+Images+Available"
#     print(url)
#     return render_template("index.html", url=url)
@app.route("/")
def index():
    url = get_image_url()
    if not url:
        url = "https://via.placeholder.com/150?text=No+Images+Available"
    count = get_visitors_count() # if you want to see the visitors count on displayed on the site, then you're another visitor 
    
    return render_template("index.html", visitors_count=count, url=url)

# PROMETHEUS: Expose /metrics for Prometheus
@app.route("/metrics")
def metrics():
    return Response(generate_latest(), content_type=CONTENT_TYPE_LATEST)


if __name__ == "__main__":
    # app.run(host="0.0.0.0", port=int(os.environ.get("WEB_PORT", 5000)))
    port = int(os.environ.get("WEB_PORT", 5002))
    print(f"Starting Flask app on port {port}")
    app.run(host="0.0.0.0", port=port) # nirali efshar lahzor lshimush be ma she ba eara yihiye beseder