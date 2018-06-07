# RealDGhostbusting
RealD Ghostbusting FPGA Code


## Release Notes

### Release 1.1 (June 7, 2018)
* Generic RAM source files were added in the "OpenSourceReleasePackage\GB_FPGA_IP\Agnostic" directory. These can be used in place of the FPGA vendor specific RAM IP.
* Test benches which compare the operation of the FPGA vendor specific RAM IP to the generic RAM models for both Xilinx and Altera were added in "OpenSourceReleasePackage\TestBench\CompareMemory"
* The Application Note was updated to describe the use of the generic RAM models to infer physical FPGA RAM.

### Release 1.0 (June 4, 2018)
* This is the initial release which matches the closely source used to provided pre-synthesized build.
* Wrappers were added to the Xilinx source files so that the component and port names of the FPGA vendor specific RAM IP matched the Altera source files.
* Test benches for the Ghost Factors and Pixel pipeline were created to assist customer integration.
* The documentation previously provided was replaced with an Applications Note (v1.0)


Contact:  tdavis@reald.com

License terms stated in the LICENSE.md file
