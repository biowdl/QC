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

import zipfile
from pathlib import Path
from typing import Dict

import pytest


def get_fastqc_module(fastqc_zip: Path, module_name: str) -> str:
    return_line = False
    text = ""
    with zipfile.ZipFile(str(fastqc_zip)) as fastqc_zipfile:
        # .stem method gives basename minus extension
        fastqc_data_location_in_zip = str(
            Path(fastqc_zip.stem) / Path("fastqc_data.txt"))
        with fastqc_zipfile.open(fastqc_data_location_in_zip, 'r'
                                 ) as fastqc_zip_handler:
            for line_bytes in fastqc_zip_handler.readlines():
                line = line_bytes.decode()
                if line.startswith(">>" + module_name):
                    return_line = True
                elif line.startswith(">>END_MODULE"):
                    return_line = False
                if return_line:
                    text += line
    return text


def adapters_present(fastqc_zip: Path) -> Dict[str, bool]:
    adapter_content = get_fastqc_module(fastqc_zip, "Adapter Content")
    lines = adapter_content.splitlines()
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


def contaminations_list(fastqc_zip: Path, only_known=False) -> Dict[str, str]:
    contaminations_module = get_fastqc_module(fastqc_zip,
                                              "Overrepresented sequences")
    lines = contaminations_module.splitlines()
    contaminations = dict()

    # lines[0] is ">>Overrepresented sequences"
    # lines[1] is "#Sequence       Count   Percentage      Possible Source"
    for line in lines[2:]:
        seq, _, _, pos_src = line.split('\t')
        # If only_known is True pos_src may not be No Hit.
        if not only_known or pos_src != "No Hit":
            contaminations[seq] = pos_src
    return contaminations


@pytest.mark.workflow(name="paired_end_zipped")
def test_paired_end_zipped_before_adapters_read_one(workflow_dir):
    fastqc_data = (
            workflow_dir / Path("test-output") / Path("ct_r1_fastqc.zip"))
    assert adapters_present(
        fastqc_data).get('Illumina Universal Adapter') is True


@pytest.mark.workflow(name="paired_end_zipped")
def test_paired_end_zipped_before_adapters_read_two(workflow_dir):
    fastqc_data = (
            workflow_dir / Path("test-output") / Path("ct_r2_fastqc.zip"))
    assert adapters_present(
        fastqc_data).get('Illumina Universal Adapter') is True


@pytest.mark.workflow(name="paired_end_zipped")
def test_paired_end_zipped_after_no_adapters_read_one(workflow_dir):
    fastqc_data = (
            workflow_dir / Path("test-output") / Path(
                "cutadapt_ct_r1_fastqc.zip")
    )
    assert adapters_present(
        fastqc_data).get('Illumina Universal Adapter') is False


@pytest.mark.workflow(name="paired_end_zipped")
def test_paired_end_zipped_after_no_adapters_read_two(workflow_dir):
    fastqc_data = (
            workflow_dir / Path("test-output") / Path(
                "cutadapt_ct_r2_fastqc.zip"))
    assert adapters_present(
        fastqc_data).get('Illumina Universal Adapter') is False
