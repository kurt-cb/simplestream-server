from bottle import Bottle, template

app = Bottle()

@app.route('/hello/<name>')
def hello(name):
    return template('Hello, {{name}}!', name=name)

# run(app, host='localhost', port=8080)