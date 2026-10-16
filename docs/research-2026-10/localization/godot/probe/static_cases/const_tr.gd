extends RefCounted
## Case: tr() in a constant initializer (expected: error, a const must be a constant expression).
const LINE: String = tr("HELLO")
