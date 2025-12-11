#!/usr/bin/env python3
"""
Simple Flask web application with metrics endpoint
"""
from flask import Flask, jsonify, request
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import time
import os

app = Flask(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

REQUEST_DURATION = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration',
    ['method', 'endpoint']
)

@app.route('/')
def index():
    """Main endpoint"""
    with REQUEST_DURATION.labels(method='GET', endpoint='/').time():
        REQUEST_COUNT.labels(method='GET', endpoint='/', status='200').inc()
        return jsonify({
            'message': 'Welcome to DevOps Challenge Application',
            'version': os.getenv('APP_VERSION', '1.0.0'),
            'status': 'healthy'
        })

@app.route('/health')
def health():
    """Health check endpoint"""
    with REQUEST_DURATION.labels(method='GET', endpoint='/health').time():
        REQUEST_COUNT.labels(method='GET', endpoint='/health', status='200').inc()
        return jsonify({
            'status': 'healthy',
            'timestamp': time.time()
        })

@app.route('/api/hello')
def hello():
    """API endpoint example"""
    name = request.args.get('name', 'World')
    with REQUEST_DURATION.labels(method='GET', endpoint='/api/hello').time():
        REQUEST_COUNT.labels(method='GET', endpoint='/api/hello', status='200').inc()
        return jsonify({
            'message': f'Hello, {name}!',
            'timestamp': time.time()
        })

@app.route('/metrics')
def metrics():
    """Prometheus metrics endpoint"""
    REQUEST_COUNT.labels(method='GET', endpoint='/metrics', status='200').inc()
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)

