--Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
--Date        : Sun Nov 10 18:36:54 2019
--Host        : DESKTOP-DUF9KV0 running 64-bit major release  (build 9200)
--Command     : generate_target clock_unit_wrapper.bd
--Design      : clock_unit_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity clock_unit_wrapper is
  port (
    clk_in1_0 : in STD_LOGIC;
    clk_out1_0 : out STD_LOGIC;
    locked_0 : out STD_LOGIC;
    reset_0 : in STD_LOGIC
  );
end clock_unit_wrapper;

architecture STRUCTURE of clock_unit_wrapper is
  component clock_unit is
  port (
    reset_0 : in STD_LOGIC;
    clk_in1_0 : in STD_LOGIC;
    clk_out1_0 : out STD_LOGIC;
    locked_0 : out STD_LOGIC
  );
  end component clock_unit;
begin
clock_unit_i: component clock_unit
     port map (
      clk_in1_0 => clk_in1_0,
      clk_out1_0 => clk_out1_0,
      locked_0 => locked_0,
      reset_0 => reset_0
    );
end STRUCTURE;
