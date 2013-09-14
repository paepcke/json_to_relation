from setuptools import setup, find_packages
setup(
    name = "json_to_relation",
    version = "0.1",
    packages = find_packages(),

    # Dependencies on other packages:
    install_requires = ['ijson>=1.0'],

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
