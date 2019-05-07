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


def get_fastqc_module(fastqc_data: Path, module_name: str) -> str:
    return_line = False
    text = ""
    with fastqc_data.open('rt') as fastqc_data_handler:
        for line in fastqc_data_handler.readlines():
            if line.startswith(">>" + module_name):
                return_line = True
            elif line.startswith(">>END_MODULE"):
                return_line = False
            if return_line:
                text += line
    return text


def adapters_present(fastqc_adapter_module: str) -> Dict[str, bool]:
    lines = fastqc_adapter_module.splitlines()
    # Line 0 is >>Adapter Content
    # Line 1 is # Position etc.
    # Get the adapters, remove position
    adapters = lines[1].split('\t')[1:]
    # Populate dict
    contains_dict = {adapter: False for adapter in adapters}
    for line in lines[2:]:
        # First entry at position is not a float
        floats = [float(column) for column in line.split('\t')[1:]]
        for i, adapter in enumerate(adapters):
            if floats[i] > 0.0:
                contains_dict[adapter] = True
    return contains_dict


def adapters_in_fastqc_data(fastqc_data: Path) -> Dict[str, bool]:
    return adapters_present(get_fastqc_module(fastqc_data, "Adapter Content"))


@pytest.mark.workflow(name="paired_end_zipped")
def test_paired_end_zipped_before_adapters_read_one(workflow_dir):
    fastqc_read_one_before = (
            workflow_dir / Path("test-output") / Path("ct_r1_fastqc")
            / Path("fastqc_data.txt"))
    assert adapters_in_fastqc_data(
        fastqc_read_one_before).get('Illumina Universal Adapter') is True


@pytest.mark.workflow(name="paired_end_zipped")
def test_paired_end_zipped_before_adapters_read_two(workflow_dir):
    fastqc_read_one_before = (
            workflow_dir / Path("test-output") / Path("ct_r2_fastqc")
            / Path("fastqc_data.txt"))
    assert adapters_in_fastqc_data(
        fastqc_read_one_before).get('Illumina Universal Adapter') is True


@pytest.mark.workflow(name="paired_end_zipped")
def test_paired_end_zipped_after_no_adapters_read_one(workflow_dir):
    fastqc_read_one_before = (
            workflow_dir / Path("test-output") / Path("cutadapt_ct_r1_fastqc")
            / Path("fastqc_data.txt"))
    assert adapters_in_fastqc_data(
        fastqc_read_one_before).get('Illumina Universal Adapter') is False


@pytest.mark.workflow(name="paired_end_zipped")
def test_paired_end_zipped_after_no_adapters_read_two(workflow_dir):
    fastqc_read_one_before = (
            workflow_dir / Path("test-output") / Path("cutadapt_ct_r2_fastqc")
            / Path("fastqc_data.txt"))
    assert adapters_in_fastqc_data(
        fastqc_read_one_before).get('Illumina Universal Adapter') is False
