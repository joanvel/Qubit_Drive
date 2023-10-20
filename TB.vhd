library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use std.textio.all;
use IEEE.math_real.all;

entity TB is
	generic
			(g_lines:integer:=11
			;g_bits:integer:=16
			;g_addr:integer:=10
			;g_dm:integer:=2
			;g_nDACs:integer:=10
			);
end entity;
Architecture rtl of TB is

	component Drive_line is
		generic
				(g_lines:integer:=g_lines
				;g_bits:integer:=g_bits
				;g_addr:integer:=g_addr
				;g_dm:integer:=g_dm
				;g_nDACs:integer:=g_nDACs
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
	end component;
	
	component ROM_TB is
		generic
			(g_addr:integer:=g_addr
			;g_bits:integer:=g_bits
			);
		PORT
			(
				address		: IN STD_LOGIC_VECTOR (g_addr-1 DOWNTO 0);
				clock		: IN STD_LOGIC  := '1';
				q		: OUT STD_LOGIC_VECTOR (g_bits-1 DOWNTO 0)
			);
	END component;
	
	
	constant const0:integer:=integer(ceil(LOG2(real(g_dm))));
	
	type t_cDACArray is array (0 to g_nDACs-1) of std_logic_vector(2+const0-1 downto 0);
	type t_BitsArray is array (0 to g_nDACs-1) of std_logic_vector(g_bits-1 downto 0);
	
	signal s_Clk:std_logic;--Added
	signal s_StaGP:std_logic_vector(g_dm-1 downto 0);--Added
	signal s_resetGP:std_logic_vector(g_dm-1 downto 0);--Added
	signal s_fGP:std_logic_vector(g_lines*g_dm-1 downto 0);--Added
	signal s_WfGP:std_logic_vector(g_dm-1 downto 0);--Added
	signal s_resetfGP:std_logic_vector(g_dm-1 downto 0);--Added
	signal s_finishGP:std_logic_vector(g_dm-1 downto 0);
	signal s_fCS:std_logic_vector(g_bits*g_dm-1 downto 0);--Added
	signal s_resetCS:std_logic_vector(g_dm-1 downto 0);--Added
	signal s_resetCP:std_logic_vector(g_dm-1 downto 0);--Added
	signal s_staCP:std_logic_vector(g_dm-1 downto 0);--Added
	signal s_DataCP:std_logic_vector(g_bits*g_dm-1 downto 0);
	signal s_Addr:std_logic_vector(g_Addr*g_dm-1 downto 0);
	signal s_finishCP:std_logic_vector(g_dm-1 downto 0);
	signal s_C:std_logic_vector(g_dm-1 downto 0);--Added
	signal s_gain:std_logic_vector(g_bits*g_dm-1 downto 0);
	signal s_cDAC:std_logic_vector((2+const0)*g_nDACs-1 downto 0);
	signal s_Signals:std_logic_vector(g_bits*g_nDACs-1 downto 0);
	
	signal s_finish:std_logic_vector(2*g_dm-1 downto 0);
	
	signal s_DACSignals:t_BitsArray;
	signal s_DACControl:t_cDACArray;
	
	file f_DAC:text;
	file f_finishGP:text;
begin
	--Defining some constants
	A:	for i in 1 to g_dm generate
			s_fGP(i*g_lines-1 downto (i-1)*g_lines)<=std_logic_vector(to_unsigned(1,g_lines));
			s_fCS(i*g_bits-1 downto (i-1)*g_bits)<=std_logic_vector(to_unsigned(2**(i+8),g_bits));
		end generate;
	B:	for i in 1 to g_nDACs generate
			s_DACSignals(i-1)<=s_Signals(g_bits*i-1 downto g_bits*(i-1));
			s_cDAC((2+const0)*i-1 downto (2+const0)*(i-1))<=s_DACControl(i-1);
		end generate;
	s_finish	<= s_finishCP & s_finishGP;
	--Clock signal
	process
	begin
		s_Clk<='0';
		wait for 10 ns;
		s_Clk<='1';
		wait for 10 ns;
	end process;
	--Resetting all the Circuits to its initial state.
	process
	begin
		s_resetGP <= (others=>'0');
		s_resetfGP <= (others=>'0');
		s_resetCS <= (others=>'0');
		s_resetCP <= (others=>'0');
		wait for 10 ns;--Total: 10 ns
		s_resetGP <= (others=>'1');
		s_resetfGP <= (others=>'1');
		s_resetCS <= (others=>'1');
		s_resetCP <= (others=>'1');
		wait for 342270 ns;--Total: 342280 ns
		s_resetCP <= (others=>'0');
		wait for 20 ns;--Total: 342300 ns
		s_resetCP <= (others=>'1');
		wait for 96400 ns;--Total: 438700 ns
		s_resetCP(0)	<= '0';
		wait for 20 ns;--Total: 438720 ns
		s_resetCP(0)	<= '1';
		wait;
	end process;
	--Writing the frequency of the Gaussian Pulse
	process
	begin
		s_Wfgp <= (others=>'0');
		wait for 20 ns;
		s_Wfgp <= (others=>'1');
		wait for 20 ns;
		s_Wfgp <= (others=>'0');
		wait;
	end process;
	--start signal and control bit
	process
	begin
		s_staGP	<=	(others=>'0');
		s_staCP	<=	(others=>'0');
		s_c		<= (others=>'0');
		s_DACControl	<= (others=>(others=>'0'));
		wait for 40 ns;--Total: 40 ns
		s_DACControl(4)<="110";--DAC I X Gate Qubit 1
		s_DACControl(5)<="111";--DAC O X Gate Qubit 1
		s_DACControl(0)<="010";--DAC I X Gate Qubit 0
		s_DACControl(1)<="011";--DAC O X Gate Qubit 0
		s_staGP(0)	<= '1';--X(PI/2) Gate to Qubit 0
		s_staGP(1)	<= '1';--X(PI/2) Gate to Qubit 1
		wait for 20 ns;--Total: 60 ns
		s_staGP(0)	<= '0';
		s_staGP(1)	<= '0';
		wait for 81920 ns;--Total: 81980 ns
		s_DACControl(0)<="000";--DAC I X Gate Qubit 0, Value=0
		s_DACControl(1)<="000";--DAC O X Gate Qubit 0, value=0
		s_DACControl(2)<="010";--DAC I Y Gate Qubit 0
		s_DACControl(3)<="011";--DAC O Y Gate Qubit 0
		wait for 20 ns;--Total: 82000 ns
		s_staGP(0)	<= '1';--Y(-PI/2) Gate to Qubit 0
		s_staGP(1)	<= '1';--X(PI/2) Gate to Qubit 1
		wait for 20 ns;--Total: 82020 ns
		s_staGP(0)	<= '0';
		s_staGP(1)	<= '0';
		wait for 81920 ns;--Total: 163940 ns
		s_DACControl(0)<="010";--DAC I X Gate Qubit 0
		s_DACControl(1)<="011";--DAC O X Gate Qubit 0
		s_DACControl(2)<="000";--DAC I Y Gate Qubit 0, value=0
		s_DACControl(3)<="000";--DAC O Y Gate Qubit 0, value=0
		s_DACControl(4)<="100";--DAC I X Gate Qubit 1, value=0
		s_DACControl(5)<="100";--DAC O X Gate Qubit 1, value=0
		s_DACControl(6)<="110";--DAC I Y Gate Qubit 1
		s_DACControl(7)<="111";--DAC O Y Gate Qubit 1
		wait for 20 ns;--Total: 163960 ns
		s_staGP(0)	<= '1';--X(-PI/2) Gate to Qubit 0
		s_staGP(1)	<= '1';--Y(PI/2) Gate to Qubit 1
		wait for 20 ns;--Total: 163980 ns
		s_staGP(0)	<= '0';
		s_staGP(1)	<= '0';
		wait for 81920 ns;--Total: 245900 ns
		s_DACControl(0)<="000";--DAC I X Gate Qubit 0, value=0
		s_DACControl(1)<="000";--DAC O X Gate Qubit 0, value=0
		s_DACControl(2)<="000";--DAC I Y Gate Qubit 0, value=0
		s_DACControl(3)<="000";--DAC O Y Gate Qubit 0, value=0
		s_DACControl(4)<="110";--DAC I X Gate Qubit 1
		s_DACControl(5)<="111";--DAC O X Gate Qubit 1
		s_DACControl(6)<="100";--DAC I Y Gate Qubit 1, value=0
		s_DACControl(7)<="100";--DAC O Y Gate Qubit 1, value=0
		wait for 20 ns;--Total: 245920 ns
		s_staGP(1)	<= '1';--X(-PI/2) Gate to Qubit 1
		wait for 20 ns;--Total: 245940 ns
		s_staGP(1)	<= '0';
		wait for 81920 ns;--Total: 327860 ns
		s_c(0)	<= '1';
		s_DACControl(4)<="100";--DAC I X Gate Qubit 1, value=0
		s_DACControl(5)<="100";--DAC O X Gate Qubit 1, value=0
		s_DACControl(8)<="001";--DAC Magnetic Flux 0
		wait for 20 ns;--Total: 327880 ns
		s_staCP(0)	<= '1';--iSWAP Gate
		wait for 20 ns;--Total: 327900 ns
		s_staCP(0)	<= '0';
		wait for 14400 ns;--Total: 342300 ns
		s_c(0)	<= '0';
		s_DACControl(0)<="010";--DAC I X Gate Qubit 0
		s_DACControl(1)<="011";--DAC O X Gate Qubit 0
		s_DACControl(8)<="000";--DAC Magnetic Flux 0, value=0
		wait for 20 ns;--Total: 342320 ns
		s_staGP(0)	<= '1';--X(PI/2) Gate to Qubit 0
		wait for 20 ns;--Total: 342340 ns
		s_staGP(0)	<= '0';
		wait for 81920 ns;--Total: 424260 ns
		s_c(0)	<= '1';
		s_DACControl(0)<="000";--DAC I X Gate Qubit 0, value=0
		s_DACControl(1)<="000";--DAC O X Gate Qubit 0, value=0
		s_DACControl(8)<="001";--DAC Magnetic Flux 0
		wait for 20 ns;--Total: 424280 ns
		s_staCP(0)	<= '1';
		wait for 20 ns;--Total: 424300 ns
		s_staCP(0)	<= '0';
		wait for 14400 ns;--Total: 438700 ns
		s_c(0)	<= '0';
		s_DACControl(8)<="000";--DAC Magentic Flux 0, value=0
		s_DACControl(4)<="110";--DAC I X Gate Qubit 1
		s_DACControl(5)<="111";--DAC O X Gate Qubit 1
		wait for 20 ns;--Total: 438720 ns
		s_staGP(1)	<= '1';
		wait for 20 ns;--Total: 438740 ns
		s_staGP(1)	<= '0';
		wait for 81920 ns;--Total: 520660 ns
		s_DACControl(4)<="100";--DAC I X Gate Qubit 1, value=0
		s_DACControl(5)<="100";--DAC O X Gate Qubit 1, value=0
		s_DACControl(6)<="110";--DAC I Y Gate Qubit 1, value=0
		s_DACControl(7)<="111";--DAC O Y Gate Qubit 1, value=0
		wait for 20 ns;--Total: 520680 ns
		s_staGP(1)	<= '1';
		wait for 20 ns;--Total: 520700 ns
		s_staGP(1)	<= '0';
		wait for 81920 ns;--Total: 602620
		s_DACControl(4)<="110";--DAC I X Gate Qubit 1
		s_DACControl(5)<="111";--DAC O X Gate Qubit 1
		s_DACControl(6)<="100";--DAC i Y Gate Qubit 1, value=0
		s_DACControl(7)<="100";--DAC O Y Gate Qubit 1, value=0
		wait for 20 ns;--Total: 602640 ns
		s_staGP(1)	<= '1';
		wait for 20 ns;--Total: 602660 ns
		s_staGP(1)	<= '0';
		wait;
	end process;
	--Gain Signal Assignation
	process
	begin
		s_gain<=(others=>'0');
		wait for 20 ns;--Total: 20 ns
		s_gain(g_bits-1 downto 0)<="0100000000000000";--X(PI/2) Gate to Qubit 0
		s_gain(g_bits*2-1 downto g_bits)<="0100000000000000";--X(PI/2) Gate to Qubit 1
		wait for 81960 ns;--Total: 81980 ns
		s_gain(g_bits-1 downto 0)<="1100000000000000";--Y(-PI/2) Gate to Qubit 0 and X(PI/2) Gate to Qubit 1 
		wait for 81960 ns;--Total: 163940 ns
		s_gain(g_bits-1 downto 0)<="1100000000000000";--X(-PI/2) Gate to Qubit 0
		s_gain(g_bits*2-1 downto g_bits)<="0100000000000000";--Y(PI/2) Gate to Qubit 1
		wait for 81960 ns;--Total: 245900 ns
		s_gain(g_bits-1 downto 0)<=(others=>'0');--I Gate to Qubit 0
		s_gain(g_bits*2-1 downto g_bits)<="1100000000000000";--X(-PI/2) Gate to Qubit 1
		wait for 81960 ns;--Total: 327860 ns
		s_gain(g_bits-1 downto 0)<="0111111111111111";--iSWAP Gate
		wait for 14440 ns;--Total: 342300 ns
		s_gain(g_bits-1 downto 0)<="0100000000000000";--X(PI/2) Gate to Qubit 0
		wait for 81960 ns;--Total: 424260 ns
		s_gain(g_bits-1 downto 0)<="0111111111111111";--iSWAP Gate
		wait for 14440 ns;--Total: 438700 ns
		s_gain(g_bits-1 downto 0)<="0100000000000000";--X(PI/2) Gate to Qubit 1
		wait;
	end process;
	--Mapping the ports
	DL:	Drive_line	port map (s_Clk	,s_staGP	,s_resetGP	,s_fGP	,s_WfGP	,s_resetfGP	,s_finishGP	,s_fCS
										,s_resetCS	,s_resetCP	,s_staCP	,s_DataCP	,s_Addr	,s_finishCP	,s_C
										,s_gain	,s_cDAC	,s_signals);
	ROM:	ROM_TB		port map (s_Addr(g_Addr-1 downto 0)		,s_Clk		,s_DataCP(g_bits-1 downto 0));
	
	s_DataCP(g_bits*g_dm-1 downto g_bits)<=(others=>'0');
	
	--Saving the Data
	process(s_Clk)
		variable l:line;
		variable status:file_open_status;
	begin
		if (rising_edge(s_Clk)) then
			--Saving the Signal of the DAC 0
			file_open(status,f_DAC,"C:\Users\Joan\Documents\TG\Senales\Drive_line\DAC0.txt",append_mode);
			assert status=open_ok
				report "No se pudo crear DAC0.txt"
				severity failure;
			write(l,to_integer(signed(s_DACSignals(0))));
			writeline(f_DAC,l);
			file_close(f_DAC);
			--Saving the Signal of the DAC 1
			file_open(status,f_DAC,"C:\Users\Joan\Documents\TG\Senales\Drive_line\DAC1.txt",append_mode);
			assert status=open_ok
				report "No se pudo crear DAC1.txt"
				severity failure;
			write(l,to_integer(signed(s_DACSignals(1))));
			writeline(f_DAC,l);
			file_close(f_DAC);
			--Saving the Signal of the DAC 2
			file_open(status,f_DAC,"C:\Users\Joan\Documents\TG\Senales\Drive_line\DAC2.txt",append_mode);
			assert status=open_ok
				report "No se pudo crear DAC2.txt"
				severity failure;
			write(l,to_integer(signed(s_DACSignals(2))));
			writeline(f_DAC,l);
			file_close(f_DAC);
			-- Saving the signal of the DAC 3
			file_open(status,f_DAC,"C:\Users\Joan\Documents\TG\Senales\Drive_line\DAC3.txt",append_mode);
			assert status=open_ok
				report "No se pudo crear DAC3.txt"
				severity failure;
			write(l,to_integer(signed(s_DACSignals(3))));
			writeline(f_DAC,l);
			file_close(f_DAC);
			--Saving the signal of the DAC 4
			file_open(status,f_DAC,"C:\Users\Joan\Documents\TG\Senales\Drive_line\DAC4.txt",append_mode);
			assert status=open_ok
				report "No se pudo crear DAC4.txt"
				severity failure;
			write(l,to_integer(signed(s_DACSignals(4))));
			writeline(f_DAC,l);
			file_close(f_DAC);
			--Saving the signal of the DAC 5
			file_open(status,f_DAC,"C:\Users\Joan\Documents\TG\Senales\Drive_line\DAC5.txt",append_mode);
			assert status=open_ok
				report "No se pudo crear DAC5.txt"
				severity failure;
			write(l,to_integer(signed(s_DACSignals(5))));
			writeline(f_DAC,l);
			file_close(f_DAC);
			--Saving the signal of the DAC 6
			file_open(status,f_DAC,"C:\Users\Joan\Documents\TG\Senales\Drive_line\DAC6.txt",append_mode);
			assert status=open_ok
				report "No se pudo crear DAC6.txt"
				severity failure;
			write(l,to_integer(signed(s_DACSignals(6))));
			writeline(f_DAC,l);
			file_close(f_DAC);
			--Saving the signal of the DAC 7
			file_open(status,f_DAC,"C:\Users\Joan\Documents\TG\Senales\Drive_line\DAC7.txt",append_mode);
			assert status=open_ok
				report "No se pudo crear DAC7.txt"
				severity failure;
			write(l,to_integer(signed(s_DACSignals(7))));
			writeline(f_DAC,l);
			file_close(f_DAC);
			--Saving the signal of the DAC 8
			file_open(status,f_DAC,"C:\Users\Joan\Documents\TG\Senales\Drive_line\DAC8.txt",append_mode);
			assert status=open_ok
				report "No se pudo crear DAC8.txt"
				severity failure;
			write(l,to_integer(signed(s_DACSignals(8))));
			writeline(f_DAC,l);
			file_close(f_DAC);
			--Saving the signal of the DAC 9
			file_open(status,f_DAC,"C:\Users\Joan\Documents\TG\Senales\Drive_line\DAC9.txt",append_mode);
			assert status=open_ok
				report "No se pudo crear DAC9.txt"
				severity failure;
			write(l,to_integer(signed(s_DACSignals(9))));
			writeline(f_DAC,l);
			file_close(f_DAC);
			--Saving the info of the flag finishGP
			file_open(status,f_finishGP,"C:\Users\Joan\Documents\TG\Senales\Drive_line\finishGP.txt",append_mode);
			assert status=open_ok
				report "No se pudo crear finishGP.txt"
				severity failure;
			write(l,to_integer(unsigned(s_finish)));
			writeline(f_finishGP,l);
			file_close(f_finishGP);
		end if;
	end process;
end rtl;