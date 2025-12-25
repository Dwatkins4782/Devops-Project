#!/usr/bin/env python3
"""
Simple Flask web application with metrics endpoint
"""
from flask import Flask, jsonify, request
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import time
import os
import logging
import socket

app = Flask(__name__)

# Configure logging with Logstash handler
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# Console handler (default)
console_handler = logging.StreamHandler()
console_handler.setLevel(logging.INFO)
console_formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
console_handler.setFormatter(console_formatter)
logger.addHandler(console_handler)

# Logstash handler (if available)
try:
    from logstash_async.handler import AsynchronousLogstashHandler
    
    logstash_host = os.getenv('LOGSTASH_HOST', 'logstash')
    logstash_port = int(os.getenv('LOGSTASH_PORT', 5000))
    
    logstash_handler = AsynchronousLogstashHandler(
        logstash_host,
        logstash_port,
        database_path=None
    )
    logger.addHandler(logstash_handler)
    logger.info(f"Logstash handler configured: {logstash_host}:{logstash_port}")
except (ImportError, Exception) as e:
    logger.warning(f"Logstash handler not available: {e}")

# Log application startup
logger.info("Application starting", extra={
    'app_name': 'devops-app',
    'version': os.getenv('APP_VERSION', '1.0.0'),
    'hostname': socket.gethostname()
})

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
        logger.info("Index endpoint accessed", extra={
            'endpoint': '/',
            'method': 'GET',
            'status': 200
        })
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
        logger.debug("Health check accessed")
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
        logger.info("Hello endpoint accessed", extra={
            'endpoint': '/api/hello',
            'method': 'GET',
            'name': name,
            'status': 200
        })
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
    logger.info(f"Starting application on port {port}")
    app.run(host='0.0.0.0', port=port, debug=False)

