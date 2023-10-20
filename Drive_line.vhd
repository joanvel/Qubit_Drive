library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

entity Drive_line is
	generic
			(g_lines:integer:=11
			;g_bits:integer:=16
			;g_addr:integer:=11
			;g_dm:integer:=2
			;g_nDACs:integer:=6
			);
	port
			(i_Clk:in std_logic
			--inputs and outputs for the Gaussian Pulse
			;i_StaGP:in std_logic_vector(g_dm-1 downto 0)
			;i_resetGP:in std_logic_vector(g_dm-1 downto 0)
			;i_fGP:in std_logic_vector(g_lines*g_dm-1 downto 0)
			;i_WfGP:in std_logic_vector(g_dm-1 downto 0)
			;i_resetfGP:in std_logic_vector(g_dm-1 downto 0)
			;o_finishGP:out std_logic_vector(g_dm-1 downto 0)
			--inputs and outputs for the sine and cosine signal generator
			;i_fCS:in std_logic_vector(g_bits*g_dm-1 downto 0)
			;i_resetCS:in std_logic_vector(g_dm-1 downto 0)
			--inputs and outputs for the custom pulse
			;i_resetCP:in std_logic_vector(g_dm-1 downto 0)
			;i_staCP:in std_logic_vector(g_dm-1 downto 0)
			;i_DataCP:in std_logic_vector(g_bits*g_dm-1 downto 0)
			;o_Addr:out std_logic_vector(g_Addr*g_dm-1 downto 0)
			;o_finishCP:out std_logic_vector(g_dm-1 downto 0)
			--extra inputs and outputs that are used by only this circuit
			;i_C:in std_logic_vector(g_dm-1 downto 0)--Pulse selector (CUstom or Gaussian)
			;i_gain:in std_logic_vector(g_bits*g_dm-1 downto 0)
			;i_cDAC:in std_logic_vector((2+integer(ceil(LOG2(real(g_dm)))))*g_nDACs-1 downto 0)--Signal selector for the DACs
			;o_signals:out std_logic_vector(g_bits*g_nDACs-1 downto 0)
			);
end entity;

Architecture rtl of Drive_line is

	component Qubit_drive is
			generic
					(g_bits:integer:=g_bits
					;g_lines:integer:=g_lines
					;g_Addr:integer:=g_addr
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
	end component;
	
	type t_Data is array (0 to g_dm-1) of std_logic_vector(g_bits-1 downto 0);
	
	constant c_MSB:integer:=4*g_dm*g_bits;
	
	constant c_dInd:integer:=(2+integer(ceil(LOG2(real(g_dm)))));
	
	signal s_Pulse:t_Data;
	
	signal s_SignalI:t_Data;
	
	signal s_SignalO:t_Data;
	
	signal s_zeros:t_Data;

begin

	s_zeros<=(others=>(others=>'0'));
	
	X:	for i in 1 to g_dm generate
			QD:	Qubit_drive	port map (i_Clk			,i_StaGP(i-1)		,i_resetGP(i-1)	,i_fGP(g_lines*i-1 downto g_lines*(i-1))
												,i_WfGP(i-1)	,i_resetfGP(i-1)	,o_finishGP(i-1)	,i_fCS(g_bits*i-1 downto g_bits*(i-1))
												,i_resetCS(i-1),i_resetCP(i-1)	,i_staCP(i-1)		,i_DataCP(g_bits*i-1 downto g_bits*(i-1))
												,o_Addr(g_addr*i-1 downto g_addr*(i-1))	,o_finishCP(i-1)	,i_C(i-1)
												,i_gain(g_bits*i-1 downto g_bits*(i-1))	,s_Pulse(i-1)
												,s_SignalI(i-1)	,s_SignalO(i-1));
		end generate;
		
	process(s_Pulse,s_SignalI,s_SignalO,i_cDAC)
		variable v_c0:std_logic_vector(1 downto 0);
		variable v_c1:std_logic_vector(c_dInd-3 downto 0);
	begin
		for j in 1 to g_nDACs loop
			v_c0:=i_cDAC((j-1)*c_dInd+1 downto (j-1)*c_dInd);
			v_c1:=i_cDAC(j*c_dInd-1 downto j*c_dInd-integer(ceil(LOG2(real(g_dm)))));
			case v_c0 is
				when "00"=>
					o_Signals(j*g_bits-1 downto (j-1)*g_bits)<=s_zeros(to_integer(unsigned(v_c1)));
				when "01"=>
					o_Signals(j*g_bits-1 downto (j-1)*g_bits)<=s_Pulse(to_integer(unsigned(v_c1)));
				when "10"=>
					o_Signals(j*g_bits-1 downto (j-1)*g_bits)<=s_SignalI(to_integer(unsigned(v_c1)));
				when "11"=>
					o_Signals(j*g_bits-1 downto (j-1)*g_bits)<=s_SignalO(to_integer(unsigned(v_c1)));
				when others=>
					NULL;
			end case;
		end loop;
	end process;
	
end rtl;