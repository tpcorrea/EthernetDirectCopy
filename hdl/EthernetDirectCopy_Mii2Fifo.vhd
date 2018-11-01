----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/20/2018 03:26:07 PM
-- Design Name: 
-- Module Name: EthernetDirectCopy_Mii2Fifo - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;
Library UNIMACRO;
use UNIMACRO.vcomponents.all;
Library xpm;
use xpm.vcomponents.all;

entity EthernetDirectCopy_Mii2Fifo is
  Generic (
        C_FIFO_ALMOST_FULL	    : integer	:= 16;
        C_FIFO_WIDTH            : integer   := 32        
        );
  Port ( 
        resetn          : in std_logic;
        enable          : in std_logic;
        MII_rx_clk      : in std_logic;
        MII_dv          : in std_logic;
        MII_rx_data     : in std_logic_vector (3 downto 0);
        MII_rx_er       : in std_logic;
        fifo_RdClk      : in std_logic;
        fifo_RdEn       : in std_logic;
        fifo_RdError    : out std_logic;
        fifo_Dout       : out std_logic_vector(31 downto 0);
        fifo_AlmostFull : out std_logic;
        fifo_Empty      : out std_logic                
        );
end EthernetDirectCopy_Mii2Fifo;

architecture Behavioral of EthernetDirectCopy_Mii2Fifo is
    type state_labels is (  IDLE,
                            PREAMBLE,
                            FILL_REG32,
                            WRITE_FIFO,
                            LAST_WRITE,  
                            ERROR);
                    
    signal current_state, next_state : state_labels;
    signal reg32 : std_logic_vector(31 downto 0);
    signal count : std_logic_vector(2 downto 0); 
    signal fifo_WrEn, fifo_WrError, fifo_Full  : std_logic;
    signal resetn_mii_clk, resetn_RdClk, fifo_reset : std_logic;
    signal reg_Dv, reg_Rx_er : std_logic;
    signal reg_rx_data, reg_rx_data_n : std_logic_vector (3 downto 0);
begin


   FIFO_DUALCLOCK_MACRO_inst : FIFO_DUALCLOCK_MACRO
   generic map (
      DEVICE => "7SERIES",            -- Target Device: "VIRTEX5", "VIRTEX6", "7SERIES" 
      ALMOST_FULL_OFFSET => to_bitvector(std_logic_vector(to_unsigned(512 - C_FIFO_ALMOST_FULL - 5,16))),  -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET => X"0008", -- Sets the almost empty threshold
      DATA_WIDTH => C_FIFO_WIDTH,   -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE => "18Kb",            -- Target BRAM, "18Kb" or "36Kb" 
      FIRST_WORD_FALL_THROUGH => FALSE) -- Sets the FIFO FWFT to TRUE or FALSE
   port map (
      ALMOSTEMPTY => open,   -- 1-bit output almost empty
      ALMOSTFULL => fifo_AlmostFull,    -- 1-bit output almost full
      DO => fifo_Dout,                  -- Output data, width defined by DATA_WIDTH parameter
      EMPTY => fifo_Empty,              -- 1-bit output empty
      FULL => fifo_Full,                -- 1-bit output full
      RDCOUNT => open,                  -- Output read count, width determined by FIFO depth
      RDERR => fifo_RdError,            -- 1-bit output read error
      WRCOUNT => open,                  -- Output write count, width determined by FIFO depth
      WRERR => fifo_WrError,            -- 1-bit output write error
      DI => reg32,                -- Input data, width defined by DATA_WIDTH parameter
      RDCLK => fifo_RdClk,              -- 1-bit input read clock
      RDEN => fifo_RdEn,                -- 1-bit input read enable
      RST => fifo_reset,                -- 1-bit input reset
      WRCLK => MII_rx_clk,              -- 1-bit input write clock
      WREN => fifo_WrEn                 -- 1-bit input write enable
   );

-- Register MII inputs
  REG_INPUT : process (MII_rx_clk)
    begin
        if rising_edge(MII_rx_clk) then
            if resetn_mii_clk = '0' then
                reg_rx_data <= x"0";
                reg_rx_data_n <= x"0";
                reg_Dv <= '0';
                reg_Rx_er <= '0';
            else
                reg_rx_data <= MII_rx_data;
                reg_rx_data_n <= reg_rx_data;
                reg_Dv <= MII_dv;
                reg_Rx_er <= MII_rx_er;            
            end if;
        end if;
    end process;

-- State-Machine    
  SYNC_PROC : process (MII_rx_clk)
   begin
      if (rising_edge(MII_rx_clk)) then
         if resetn_mii_clk = '0' then
            current_state <= IDLE;
         else
            current_state <= next_state;
         end if;
          if current_state = FILL_REG32 or current_state = WRITE_FIFO then
            count <= std_logic_vector(unsigned(count) + 1);
          else
            count <= b"000";
          end if;
      end if;
   end process;

   STATE_DECODE: process (current_state, reg_Dv, reg_rx_data, reg_rx_er, fifo_WrError, count)
   begin
      --declare default state 
      next_state <= current_state; 
      case (current_state) is
        when IDLE =>
            if reg_Dv = '1' and enable = '1' then
                next_state <= PREAMBLE;
            end if;            
        when PREAMBLE =>
            if reg_Dv = '0' then
                next_state <= IDLE;
            elsif reg_rx_data = x"D" and reg_rx_data_n = x"5" then
                next_state <= FILL_REG32;
            end if;
        when FILL_REG32 =>
            if reg_rx_er = '1' or fifo_WrError = '1' then
                next_state <= ERROR;
            elsif reg_Dv = '0' then
                next_state <= LAST_WRITE;
            elsif count = b"111" then
                next_state <= WRITE_FIFO;
            end if;
        when WRITE_FIFO =>
            if reg_Dv = '0' then
                next_state <= IDLE;
            else
                next_state <= FILL_REG32;
            end if;
        when LAST_WRITE =>
            next_state <= IDLE;
        when ERROR =>
            next_state <= IDLE;
        when others =>
            next_state <= IDLE;
      end case;
   end process;    

   OUTPUT_DECODE: process (current_state)
   begin
      -- default outputs
      fifo_WrEn <= '0';
      case (current_state) is
        when IDLE =>
        when PREAMBLE =>
        when FILL_REG32 =>
        when WRITE_FIFO =>
            fifo_WrEn <= '1';
        when LAST_WRITE =>
            fifo_WrEn <= '1';
        when ERROR =>
        when others =>
      end case;
   end process; 
   
-- Pack data into 32 bits register
  PACK_DATA : process (MII_rx_clk)
  begin
      if rising_edge(MII_rx_clk) then
        if resetn_mii_clk = '0' then
              reg32 <= (others => '0');
        else
            case count is
-- LITTLE ENDIAN
                when b"000" => 
                    reg32 <= x"0000000" & reg_rx_data;
                when b"001" => 
                     reg32(7 downto 4) <= reg_rx_data;
                when b"010" => 
                     reg32(11 downto 8) <= reg_rx_data;
                when b"011" => 
                     reg32(15 downto 12) <= reg_rx_data;
                when b"100" => 
                     reg32(19 downto 16) <= reg_rx_data;
                when b"101" => 
                      reg32(23 downto 20)<= reg_rx_data;
                when b"110" => 
                     reg32(27 downto 24) <= reg_rx_data;
                when b"111" => 
                     reg32(31 downto 28) <= reg_rx_data;
--  BIG ENDIAN                     
--                when b"000" => 
--                    reg32 <= reg_rx_data & x"0000000";
--                when b"001" => 
--                     reg32(27 downto 24) <= reg_rx_data;
--                when b"010" => 
--                     reg32(23 downto 20) <= reg_rx_data;
--                when b"011" => 
--                     reg32(19 downto 16) <= reg_rx_data;
--                when b"100" => 
--                     reg32(15 downto 12) <= reg_rx_data;
--                when b"101" => 
--                     reg32(11 downto 8) <= reg_rx_data;
--                when b"110" => 
--                     reg32(7 downto 4) <= reg_rx_data;
--                when b"111" => 
--                     reg32(3 downto 0) <= reg_rx_data;
               when others =>
                    reg32 <= reg_rx_data & x"0000000";
           end case;
        end if;
      end if;
  end process;

  xpm_cdc_async_rst_inst1 : xpm_cdc_async_rst
   generic map (
      DEST_SYNC_FF => 6,    -- DECIMAL; range: 2-10
      RST_ACTIVE_HIGH => 0  -- DECIMAL; 0=active low reset, 1=active high reset
   )
   port map (
      dest_arst => resetn_mii_clk, -- 1-bit output: src_arst asynchronous reset signal synchronized to destination CD
      dest_clk => MII_rx_clk,   -- 1-bit input: Destination clock.
      src_arst => resetn    -- 1-bit input: Source asynchronous reset signal.
   );
   
  xpm_cdc_async_rst_inst2 : xpm_cdc_async_rst
    generic map (
       DEST_SYNC_FF => 6,    -- DECIMAL; range: 2-10
       RST_ACTIVE_HIGH => 0  -- DECIMAL; 0=active low reset, 1=active high reset
    )
    port map (
       dest_arst => resetn_RdClk, -- 1-bit output: src_arst asynchronous reset signal synchronized to destination CD
       dest_clk => fifo_RdClk,   -- 1-bit input: Destination clock.
       src_arst => resetn    -- 1-bit input: Source asynchronous reset signal.
    );
    
    fifo_reset <= resetn_RdClk nand resetn_mii_clk;
   
end Behavioral;
