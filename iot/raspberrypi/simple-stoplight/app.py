# Import libraries.
import RPi.GPIO as GPIO
import time
import flask
import threading

# Initialize variables.
LIGHT_DELAY = 1
R_LED = 17
Y_LED = 21
G_LED = 22
app = flask.Flask(__name__)

# Perform setup.
GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)
GPIO.setup(R_LED, GPIO.OUT)
GPIO.setup(Y_LED, GPIO.OUT)
GPIO.setup(G_LED, GPIO.OUT)

# Define functions.
def clear():
    GPIO.output(R_LED, GPIO.LOW)
    GPIO.output(Y_LED, GPIO.LOW)
    GPIO.output(G_LED, GPIO.LOW)
    
def red():
    clear()
    GPIO.output(R_LED, GPIO.HIGH)
    
def yellow():
    clear()
    GPIO.output(Y_LED, GPIO.HIGH)

def green():
    clear()
    GPIO.output(G_LED, GPIO.HIGH)

def auto():
    auto_func = threading.currentThread()
    while getattr(auto_func, "run", True):
        green()
        time.sleep(3*LIGHT_DELAY)
        yellow()
        time.sleep(1*LIGHT_DELAY)
        red()
        time.sleep(4*LIGHT_DELAY)
    return
auto_func = threading.Thread(target = auto)


# Define routes.
@app.route("/")
def routeAuto():
    auto_func = threading.Thread(target = auto)
    auto_func.start()
    return flask.render_template('auto.html')

@app.route("/green")
def routeGreen():
    if auto_func.isAlive():
        auto_func.run = False
        auto_func.join()
    green()
    return flask.render_template('green.html')

@app.route("/yellow")
def routeYellow():
    if auto_func.isAlive():
        auto_func.run = False
        auto_func.join()
    yellow()
    return flask.render_template('yellow.html')

@app.route("/red")
def routeRed():
    if auto_func.isAlive():
        auto_func.run = False
        auto_func.join()
    red()
    return flask.render_template('red.html')

# Launch application.
if __name__ == "__main__":
    app.run(host='0.0.0.0',port="80")
