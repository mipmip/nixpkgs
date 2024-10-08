{
  lib,
  buildPythonPackage,
  fetchPypi,
  hypothesis,
  pythonOlder,
  pytestCheckHook,
  pytest-cov-stub,
}:

buildPythonPackage rec {
  pname = "pyisbn";
  version = "1.3.1";
  format = "setuptools";

  disabled = pythonOlder "3.7";

  src = fetchPypi {
    inherit pname version;
    sha256 = "06fm9rn31cb4b61hzy63cnwfjpppgyy517k8a04gzcv9g60n7xbh";
  };

  nativeCheckInputs = [
    hypothesis
    pytestCheckHook
    pytest-cov-stub
  ];

  pythonImportsCheck = [ "pyisbn" ];

  meta = with lib; {
    description = "Python module for working with 10- and 13-digit ISBNs";
    homepage = "https://github.com/JNRowe/pyisbn";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ eigengrau ];
  };
}
