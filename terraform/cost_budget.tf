resource "aws_budgets_budget" "monthly_cost_alert" {
  name         = "monthly-cost-budget"
  budget_type  = "COST"
  limit_amount = "21.50"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = ["adrianmagarola@gmail.com"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = ["adrianmagarola@gmail.com"]
  }
}
