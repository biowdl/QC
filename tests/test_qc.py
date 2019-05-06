# MIT License
#
# Copyright (c) 2018 Sequencing Analysis Support Core - Leiden University Medical Center
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

from pathlib import Path
from typing import Dict

import pytest


def get_fastqc_adapter_module(fastqc_data: Path) -> str:
    return_line = False
    text = ""
    with fastqc_data.open('rt') as fastqc_data_handler:
        for line in fastqc_data_handler.readlines():
            if line.startswith(">>Adapter Content"):
                return_line = True
            elif line.startswith(">>END_MODULE"):
                return_line = False
            if return_line:
                text += line
    return text


def adapters_present(fastqc_adapter_module: str) -> Dict[str, bool]:

    pass


def test_paired_end_zipped_before_adapters(name="paired_end_zipped"):
    pass
