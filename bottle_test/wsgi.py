from bottle import Bottle, template
import bottle

app = application = Bottle()

@app.route('/hello/<name>')
def hello(name):
    return template('Hello, {{name}}!', name=name)

@app.route('/there/<name>')
def there(name):
    return template('there, {{name}}!', name=name)

# run(app, host='localhost', port=8080)