from setuptools import setup, find_packages
setup(
    name = "json_to_relation",
    version = "0.1",
    packages = find_packages(),

    # Dependencies on other packages:
    setup_require    = ['nose>=1.1.2'],
    install_requires = ['ijson>=1.0', 'pymongo>=2.6.2'],
    tests_require    = ['mongomock>=1.0.1'],

    # Unit tests; they are initiated via 'python setup.py test'
    test_suite       = 'json_to_relation/test',

    package_data = {
        # If any package contains *.txt or *.rst files, include them:
     #   '': ['*.txt', '*.rst'],
        # And include any *.msg files found in the 'hello' package, too:
     #   'hello': ['*.msg'],
    },

    # metadata for upload to PyPI
    author = "Andreas Paepcke",
    #author_email = "me@example.com",
    description = "Converts file with multiple JSON objects to one relational table.",
    license = "BSD",
    keywords = "json, relation",
    url = "https://github.com/paepcke/json_to_relation",   # project home page, if any
)
