import setuptools
import os

with open("README.md", "r") as f:
    long_description = f.read()

setuptools.setup(
    name="COVID-MCS",
    version=os.environ.get("VERSION", "0.0.0"),
    author="Burke O'Brien",
    author_email="burkeob@gmail.com",
    description=(
        "Uses methodology described in Ganz (2019) to asses the shape of COVID-19 cases."
    ),
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/burkeob/COVID-MCS",
    packages=setuptools.find_packages(),
    install_requires=["paramtools"],
    include_package_data=True,
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
)
