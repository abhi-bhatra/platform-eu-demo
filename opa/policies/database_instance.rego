# Standalone Rego for DatabaseInstance (Conftest / OPA bundle)
# Same logic as Gatekeeper ConstraintTemplate — use for CI or policy server
package databaseinstancepolicy

deny[msg] {
  obj := input
  obj.kind == "DatabaseInstance"
  obj.apiVersion == "myplatform.io/v1"
  obj.spec.public == true
  msg := "Database must be private! Public access is not allowed."
}

deny[msg] {
  obj := input
  obj.kind == "DatabaseInstance"
  obj.apiVersion == "myplatform.io/v1"
  size := obj.spec.size
  size == "extra-large"
  msg := sprintf("Instance size %q is not allowed. Use small or medium.", [size])
}
