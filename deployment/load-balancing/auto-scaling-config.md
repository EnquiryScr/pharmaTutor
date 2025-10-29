# Load Balancing and Auto-Scaling Configuration for Tutoring Platform

## Overview

This document outlines the comprehensive load balancing and auto-scaling configuration for the tutoring platform, ensuring high availability, scalability, and optimal performance across all environments.

## Architecture Overview

```
Internet
    ↓
CloudFlare CDN
    ↓
AWS Application Load Balancer
    ↓
Auto Scaling Groups (Multiple AZs)
    ↓
EC2 Instances / ECS Tasks
    ↓
RDS Read Replicas
    ↓
ElastiCache Redis Cluster
```

## AWS Application Load Balancer Configuration

### ALB Terraform Configuration

```hcl
# Application Load Balancer
resource "aws_lb" "tutoring_platform_alb" {
  name               = "tutoring-platform-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = var.public_subnet_ids

  enable_deletion_protection = true
  enable_http2              = true

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.id
    prefix  = "tutoring-platform"
    enabled = true
  }

  tags = {
    Name        = "tutoring-platform-alb"
    Environment = var.environment
    Project     = "tutoring-platform"
  }
}

# Target Group
resource "aws_lb_target_group" "api_target_group" {
  name        = "tutoring-platform-api-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  stickiness {
    enabled         = true
    cookie_duration = 86400
    type            = "lb_cookie"
  }

  tags = {
    Name        = "tutoring-platform-api-tg"
    Environment = var.environment
  }
}

# Listener Rules
resource "aws_lb_listener" "api_listener" {
  load_balancer_arn = aws_lb.tutoring_platform_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.tutoring_platform.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_target_group.arn
  }
}

# HTTPS Redirect Rule
resource "aws_lb_listener_rule" "redirect_http_to_https" {
  listener_arn = aws_lb_listener.api_listener.arn
  priority     = 100

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    field  = "host-header"
    values = [var.domain_name, "www.${var.domain_name}"]
  }
}

# Health Check Rule
resource "aws_lb_listener_rule" "health_check" {
  listener_arn = aws_lb_listener.api_listener.arn
  priority     = 200

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "healthy"
      status_code  = "200"
    }
  }

  condition {
    field  = "path-pattern"
    values = ["/health"]
  }
}

# API Routing Rules
resource "aws_lb_listener_rule" "api_routing" {
  listener_arn = aws_lb_listener.api_listener.arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_target_group.arn
  }

  condition {
    field  = "path-pattern"
    values = ["/api/*"]
  }
}

# Security Groups
resource "aws_security_group" "alb" {
  name_prefix = "tutoring-platform-alb-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "tutoring-platform-alb-sg"
    Environment = var.environment
  }
}
```

## Auto Scaling Configuration

### ECS Auto Scaling

```hcl
# ECS Cluster
resource "aws_ecs_cluster" "tutoring_platform" {
  name = "tutoring-platform-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.ecs_execute_command.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.ecs_exec.name
      }
    }
  }

  tags = {
    Name        = "tutoring-platform-cluster"
    Environment = var.environment
  }
}

# ECS Service
resource "aws_ecs_service" "api_service" {
  name            = "tutoring-platform-api"
  cluster         = aws_ecs_cluster.tutoring_platform.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.api_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.api.id]
    subnets         = var.private_subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api_target_group.arn
    container_name   = "tutoring-api"
    container_port   = 3000
  }

  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
    
    deployment_circuit_breaker {
      enable   = true
      rollback = true
    }
  }

  service_connect_configuration {
    namespace = aws_service_discovery_http_namespace.tutoring_platform.arn
    service {
      port_name = "api"
      discovery_name = "tutoring-platform-api"
      
      client_alias {
        port     = 3000
        dns_name = "api.tutoring-platform.local"
      }
    }
  }

  tags = {
    Name        = "tutoring-platform-api-service"
    Environment = var.environment
  }
}

# Application Auto Scaling Target
resource "aws_appautoscaling_target" "api_target" {
  max_capacity       = var.api_max_capacity
  min_capacity       = var.api_min_capacity
  resource_id        = "service/${aws_ecs_cluster.tutoring_platform.name}/${aws_ecs_service.api_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# CPU-based scaling policy
resource "aws_appautoscaling_policy" "api_cpu_scaling" {
  name               = "tutoring-platform-api-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api_target.resource_id
  scalable_dimension = aws_appautoscaling_target.api_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70.0

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# Memory-based scaling policy
resource "aws_appautoscaling_policy" "api_memory_scaling" {
  name               = "tutoring-platform-api-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api_target.resource_id
  scalable_dimension = aws_appautoscaling_target.api_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 80.0

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# Request count-based scaling policy
resource "aws_appautoscaling_policy" "api_request_scaling" {
  name               = "tutoring-platform-api-request-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api_target.resource_id
  scalable_dimension = aws_appautoscaling_target.api_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 1000.0

    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.tutoring_platform_alb.arn_suffix}/${aws_lb_target_group.api_target_group.arn_suffix}"
    }

    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}
```

### EC2 Auto Scaling (Alternative)

```hcl
# Launch Template
resource "aws_launch_template" "tutoring_platform" {
  name_prefix   = "tutoring-platform-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.api.arn
  }

  security_groups = [aws_security_group.api.id]

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    environment = var.environment
    cluster_name = aws_ecs_cluster.tutoring_platform.name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "tutoring-platform"
      Environment = var.environment
      Project     = "tutoring-platform"
      Cluster     = aws_ecs_cluster.tutoring_platform.name
    }
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_type = "gp3"
      volume_size = var.volume_size
      iops        = 3000
      throughput  = 125
      delete_on_termination = true
      encrypted   = true
      kms_key_id  = aws_kms_key.ebs.arn
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "tutoring_platform" {
  name                = "tutoring-platform-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.api_target_group.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.tutoring_platform.id
    version = "$Latest"
  }

  termination_policies = ["OldestInstance"]

  tag {
    key                 = "Name"
    value               = "tutoring-platform"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "tutoring_platform_scale_up" {
  name                   = "tutoring-platform-scale-up"
  autoscaling_group_name = aws_autoscaling_group.tutoring_platform.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 2
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

resource "aws_autoscaling_policy" "tutoring_platform_scale_down" {
  name                   = "tutoring-platform-scale-down"
  autoscaling_group_name = aws_autoscaling_group.tutoring_platform.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

# CloudWatch Alarms for Scaling
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "tutoring-platform-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Scale up when CPU > 80% for 5 minutes"

  alarm_actions = [aws_autoscaling_policy.tutoring_platform_scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.tutoring_platform.name
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "tutoring-platform-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "Scale down when CPU < 30% for 25 minutes"

  alarm_actions = [aws_autoscaling_policy.tutoring_platform_scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.tutoring_platform.name
  }

  tags = {
    Environment = var.environment
  }
}
```

## Database Scaling Configuration

### RDS Read Replicas

```hcl
# Primary DB Instance
resource "aws_db_instance" "primary" {
  identifier = "tutoring-platform-primary"

  engine         = "postgres"
  engine_version = "13.7"
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id           = aws_kms_key.rds.arn

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  performance_insights_enabled = true
  monitoring_interval         = 60
  monitoring_role_arn        = aws_iam_role.rds_monitoring.arn

  deletion_protection = true
  skip_final_snapshot = false
  final_snapshot_identifier = "tutoring-platform-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = {
    Name        = "tutoring-platform-primary"
    Environment = var.environment
    Role        = "primary"
  }
}

# Read Replicas
resource "aws_db_instance" "read_replica" {
  count = var.db_read_replica_count

  identifier = "tutoring-platform-read-replica-${count.index}"

  engine         = aws_db_instance.primary.engine
  engine_version = aws_db_instance.primary.engine_version
  instance_class = var.db_read_replica_instance_class

  replicate_source_db = aws_db_instance.primary.identifier

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 0
  monitoring_interval     = 60
  monitoring_role_arn    = aws_iam_role.rds_monitoring.arn

  performance_insights_enabled = true

  tags = {
    Name        = "tutoring-platform-read-replica-${count.index}"
    Environment = var.environment
    Role        = "read-replica"
  }
}

# CloudWatch Alarms for RDS
resource "aws_cloudwatch_metric_alarm" "db_cpu_high" {
  count = length(aws_db_instance.read_replica) + 1

  alarm_name          = "tutoring-platform-db-cpu-${count.index}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Scale up database or add read replicas when CPU > 80%"

  alarm_actions = [
    aws_sns_topic.db_alerts.arn
  ]

  dimensions = {
    DBInstanceIdentifier = count.index == 0 ? aws_db_instance.primary.identifier : aws_db_instance.read_replica[count.index - 1].identifier
  }

  tags = {
    Environment = var.environment
  }
}
```

## Redis Clustering Configuration

```hcl
# ElastiCache Replication Group
resource "aws_elasticache_replication_group" "tutoring_platform" {
  replication_group_id       = "tutoring-platform-redis"
  description                = "Redis cluster for tutoring platform"

  node_type                  = var.redis_node_type
  port                       = 6379
  parameter_group_name       = "default.redis7"
  num_cache_clusters         = var.redis_num_cache_clusters

  engine_version            = "7.0"
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                = var.redis_auth_token
  kms_key_id               = aws_kms_key.redis.arn

  subnet_group_name = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "slow-log"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "engine-log"
  }

  tags = {
    Name        = "tutoring-platform-redis"
    Environment = var.environment
  }
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  name       = "tutoring-platform-redis-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "tutoring-platform-redis-subnet-group"
    Environment = var.environment
  }
}
```

## Load Testing Configuration

```yaml
# k6 Load Testing Script
# load-test.js

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const responseTime = new Trend('response_time');

export const options = {
  stages: [
    { duration: '2m', target: 100 }, // Ramp up to 100 users
    { duration: '5m', target: 100 }, // Stay at 100 users
    { duration: '2m', target: 200 }, // Ramp up to 200 users
    { duration: '5m', target: 200 }, // Stay at 200 users
    { duration: '2m', target: 0 },   // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'], // 95% of requests must complete within 2s
    http_req_failed: ['rate<0.01'],    // Error rate must be less than 1%
    errors: ['rate<0.01'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'https://api.tutoring-platform.com';

export default function() {
  // Test API endpoints
  const endpoints = [
    '/health',
    '/api/v1/auth/login',
    '/api/v1/users/profile',
    '/api/v1/sessions',
    '/api/v1/assignments',
  ];

  for (const endpoint of endpoints) {
    const response = http.get(`${BASE_URL}${endpoint}`, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer test-token',
      },
    });

    const success = check(response, {
      [`status is 200 for ${endpoint}`]: (r) => r.status === 200,
      [`response time < 2s for ${endpoint}`]: (r) => r.timings.duration < 2000,
    });

    errorRate.add(!success);
    responseTime.add(response.timings.duration);

    sleep(1);
  }

  // Test POST requests
  const loginData = {
    email: 'test@example.com',
    password: 'testpassword',
  };

  const loginResponse = http.post(`${BASE_URL}/api/v1/auth/login`, 
    JSON.stringify(loginData), 
    { 
      headers: { 'Content-Type': 'application/json' }
    }
  );

  check(loginResponse, {
    'login status is 200': (r) => r.status === 200,
    'login response time < 1s': (r) => r.timings.duration < 1000,
  });

  const authToken = loginResponse.json('token');
  
  if (authToken) {
    // Test authenticated endpoint
    const profileResponse = http.get(`${BASE_URL}/api/v1/users/profile`, {
      headers: {
        'Authorization': `Bearer ${authToken}`,
      },
    });

    check(profileResponse, {
      'profile status is 200': (r) => r.status === 200,
    });
  }

  sleep(2);
}

export function handleSummary(data) {
  return {
    'load-test-results.json': JSON.stringify(data),
    'load-test-results.html': htmlReport(data),
    'load-test-results.txt': textSummary(data, { indent: ' ', enableColors: true }),
  };
}
```

## Monitoring and Alerting

```yaml
# CloudWatch Dashboard Configuration
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "app/tutoring-platform-alb"],
          [".", "HTTPCode_Target_2XX", ".", "."],
          [".", "HTTPCode_Target_4XX", ".", "."],
          [".", "HTTPCode_Target_5XX", ".", "."]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "us-east-1",
        "title": "Load Balancer Requests and Response Codes",
        "yAxis": {
          "left": {
            "min": 0
          }
        }
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "app/tutoring-platform-alb"],
          [".", "ActiveConnectionCount", ".", "."],
          [".", "NewConnectionCount", ".", "."]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "Load Balancer Performance Metrics"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 6,
      "width": 24,
      "height": 6,
      "properties": {
        "metrics": [
          ["AWS/ECS", "CPUUtilization", "ServiceName", "tutoring-platform-api"],
          [".", "MemoryUtilization", ".", "."]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "ECS Service Resource Utilization"
      }
    }
  ]
}
```

## Performance Optimization

### CDN Configuration (CloudFlare)

```javascript
// CloudFlare Workers Script
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  const url = new URL(request.url);
  
  // Cache static assets
  if (url.pathname.match(/\.(js|css|png|jpg|jpeg|gif|svg|woff|woff2)$/)) {
    const cacheKey = new Request(url, request);
    const cache = caches.default;
    
    let response = await cache.match(cacheKey);
    
    if (!response) {
      response = await fetch(request);
      
      // Cache static assets for 1 year
      if (response.status === 200) {
        const responseClone = response.clone();
        const headers = new Headers(responseClone.headers);
        headers.set('Cache-Control', 'public, max-age=31536000, immutable');
        
        await cache.put(cacheKey, new Response(responseClone.body, {
          status: responseClone.status,
          statusText: responseClone.statusText,
          headers: headers
        }));
      }
    }
    
    return response;
  }
  
  // API endpoints - minimal caching
  if (url.pathname.startsWith('/api/')) {
    const response = await fetch(request);
    const headers = new Headers(response.headers);
    headers.set('Cache-Control', 'no-cache, no-store, must-revalidate');
    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers: headers
    });
  }
  
  // Default handling
  return fetch(request);
}
```

This comprehensive load balancing and auto-scaling configuration ensures the tutoring platform can handle varying loads efficiently while maintaining high availability and performance.