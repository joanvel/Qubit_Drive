library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity Qubit_drive is
	generic
			(g_bits:integer:=16
			;g_lines:integer:=11
			;g_Addr:integer:=8
			);
	port
		(i_Clk:in std_logic--Clock signal for the whole circuit
		--inputs and outputs for the Gaussian Pulse
		;i_StaGP:in std_logic
		;i_resetGP:in std_logic
		;i_fGP:in std_logic_vector(g_lines-1 downto 0)
		;i_WfGP:in std_logic
		;i_resetfGP:in std_logic
		;o_finishGP:out std_logic
		--inputs and outputs for the sine and cosine signal generator
		;i_fCS:in std_logic_vector(g_bits-1 downto 0)
		;i_resetCS:in std_logic
		--inputs and outputs for the custom pulse
		;i_resetCP:in std_logic
		;i_staCP:in std_logic
		;i_DataCP:in std_logic_vector(g_bits-1 downto 0)
		;o_Addr:out std_logic_vector(g_Addr-1 downto 0)
		;o_finishCP:out std_logic
		--extra inputs and outputs that are used by only this circuit
		;i_C:in std_logic--Pulse selector (CUstom or Gaussian)
		;i_gain:in std_logic_vector(g_bits-1 downto 0)
		;o_Pulse:out std_logic_vector(g_bits-1 downto 0)
		;o_signalI:out std_logic_vector(g_bits-1 downto 0)--Signal in Phase
		;o_signalO:out std_logic_vector(g_bits-1 downto 0)--Signal Out of phase
		);
end entity;

Architecture rtl of Qubit_drive is
	
	component GaussianP is
		generic
				(g_lines:integer:=g_lines
				;g_bits:integer:=g_bits
				);
		port
			(i_Clk:in std_logic
			;i_sta:in std_logic
			;i_reset:in std_logic
			;i_Data:in std_logic_vector(g_lines-1 downto 0)
			;i_WData:in std_logic
			;i_ResetData:in std_logic
			;o_finish:out std_logic
			;o_Data:out std_logic_vector(g_bits-1 downto 0)
			);
	end component;
	
	component DDS_sine_and_cosine is
		generic
				(g_bits:integer:=g_bits);
		port
			(i_Clk:in std_logic
			;i_fctrl:in std_logic_vector(g_bits-1 downto 0)
			;i_reset:in std_logic
			;o_sin:out std_logic_vector(g_bits-1 downto 0)
			;o_cos:out std_logic_vector(g_bits-1 downto 0)
			);
	end component;
	
	component Custom_Pulse is
		generic
				(g_bits:integer:=g_bits
				;g_lines:integer:=g_Addr
				);
		port
			(i_Clk:in std_logic
			;i_reset:in std_logic
			;i_sta:in std_logic
			;i_Data:in std_logic_vector(g_bits-1 downto 0)
			;o_Data:out std_logic_vector(g_bits-1 downto 0)
			;o_Addr:out std_logic_vector(g_lines-1 downto 0)
			;flag:out std_logic
			);
	end component;
	
	signal s_DataGP:std_logic_vector(g_bits-1 downto 0);
	signal s_sin:std_logic_vector(g_bits-1 downto 0);
	signal s_cos:std_logic_vector(g_bits-1 downto 0);
	signal s_DataCP:std_logic_vector(g_bits-1 downto 0);
	signal s_Temp0:std_logic_vector(g_bits-1 downto 0);--Signal that connects the multiplexor with the gain multiplier
	signal s_Temp1:std_logic_vector(2*g_bits-1 downto 0);--Signal that connects the gain multiplier with the other multipliers
	
	signal s_signalI:std_logic_vector(2*g_bits-1 downto 0);
	signal s_signalO:std_logic_vector(2*g_bits-1 downto 0);
begin
	
	GP:	GaussianP	port map (i_Clk, i_staGP, i_resetGP, i_fGP, i_WfGP, i_resetfGP, o_finishGP, s_DataGP);
	DDSC:	DDS_sine_and_cosine	port map (i_Clk, i_fCS, i_resetCS, s_sin, s_cos);
	CP:	Custom_Pulse	port map (i_Clk, i_resetCP, i_staCP, i_DataCP, s_DataCP, o_Addr, o_finishCP);
	
	s_Temp0 <= s_DataGP when i_C = '0' else
					s_DataCP;
					
	s_Temp1 <= std_logic_vector(signed(s_Temp0)*signed(i_gain));
	
	o_Pulse <= s_Temp1(2*g_bits-2 downto g_bits-1);
	
	s_signalI <= std_logic_vector(signed(s_Temp1(2*g_bits-2 downto g_bits-1))*signed(s_cos));
	
	s_signalO <= std_logic_vector(signed(s_Temp1(2*g_bits-2 downto g_bits-1))*signed(s_sin));
	
	o_signalI <= s_signalI(2*g_bits-3 downto g_bits-2);
	
	o_signalO <= s_signalO(2*g_bits-3 downto g_bits-2);
	
end rtl;