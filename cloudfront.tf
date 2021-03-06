// Create a Cloudfront distribution for the static website
resource "aws_cloudfront_distribution" "website_cdn" {
  enabled = true

  price_class  = "PriceClass_200"
  http_version = "http2"

  origin {
    origin_id   = "origin-bucket-${aws_s3_bucket.bucket.id}"
    domain_name = aws_s3_bucket.bucket.bucket_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  default_root_object = "index.html"

  custom_error_response {
    error_code            = "404"
    error_caching_min_ttl = "360"
    response_code         = var.custom_not_found_response_code
    response_page_path    = var.custom_not_found_response_path
  }

  custom_error_response {
    error_code            = "403"
    error_caching_min_ttl = "360"
    response_code         = var.custom_forbidden_response_code
    response_page_path    = var.custom_forbidden_response_path
  }

  default_cache_behavior {
    allowed_methods = var.allowed_methods
    cached_methods  = var.cached_methods

    forwarded_values {
      query_string = false

      headers = var.forwarded_headers

      cookies {
        forward = "none"
      }
    }

    min_ttl          = var.default_cache_behavior_min_ttl
    default_ttl      = var.default_cache_behavior_default_ttl
    max_ttl          = var.default_cache_behavior_max_ttl
    target_origin_id = "origin-bucket-${aws_s3_bucket.bucket.id}"

    // This redirects any HTTP request to HTTPS.
    viewer_protocol_policy = var.viewer_protocol_policy
    compress               = true

    dynamic "lambda_function_association" {
      for_each = var.lambda_function_association
      content {
        # TF-UPGRADE-TODO: The automatic upgrade tool can't predict
        # which keys might be set in maps assigned here, so it has
        # produced a comprehensive set here. Consider simplifying
        # this after confirming which keys can be set in practice.

        event_type   = lambda_function_association.value.event_type
        include_body = lookup(lambda_function_association.value, "include_body", null)
        lambda_arn   = lambda_function_association.value.lambda_arn
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1"
  }

  aliases = var.aliases
}

