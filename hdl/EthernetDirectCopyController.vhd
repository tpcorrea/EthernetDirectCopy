----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/20/2018 02:02:25 PM
-- Design Name: 
-- Module Name: EthernetDirectCopyController - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity EthernetDirectCopy_Controller is
    generic (
        C_M_AXI_ADDR_WIDTH  : integer range 32 to 64    := 32;
        C_LENGTH_WIDTH      : INTEGER range 12 to 20 := 12;
        C_NATIVE_DATA_WIDTH : INTEGER range 32 to 128 := 32;
		C_AXI_BURST_LEN	    : integer	:= 16
    );
    port (
        clk             : in std_logic;
        resetn          : in std_logic;
        enable          : in std_logic;
        fifo_RdEn       : out std_logic;
        fifo_RdError    : in std_logic;
        fifo_Dout       : in std_logic_vector(31 downto 0);
        fifo_AlmostFull : in std_logic;
        fifo_Empty      : in std_logic;
        MII_dv          : in std_logic;
        initial_addr    : in  std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
        -- IPIC Request/Qualifiers
        ip2bus_mstwr_req           : out  std_logic                                           ;-- IPIC CMD
        ip2bus_mst_addr            : out  std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0)     ;-- IPIC CMD
        ip2bus_mst_length          : out  std_logic_vector(C_LENGTH_WIDTH-1 downto 0)         ;-- IPIC CMD
        ip2bus_mst_be              : out  std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);-- IPIC CMD
        ip2bus_mst_type            : out  std_logic                                           ;-- IPIC CMD
        ip2bus_mst_reset           : out  std_logic                                           ;-- IPIC CMD
        -- IPIC Request Status Reply
        bus2ip_mst_cmdack          : in std_logic                                           ;-- IPIC Stat
        bus2ip_mst_cmplt           : in std_logic                                           ;-- IPIC Stat
        bus2ip_mst_error           : in std_logic                                           ;-- IPIC Stat
        -- IPIC Write LocalLink Channel
        ip2bus_mstwr_d             : out  std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0)    ;-- IPIC WR LLink
        ip2bus_mstwr_rem           : out  std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);-- IPIC WR LLink
        ip2bus_mstwr_sof_n         : out  std_logic                                           ;-- IPIC WR LLink
        ip2bus_mstwr_eof_n         : out  std_logic                                           ;-- IPIC WR LLink
        ip2bus_mstwr_src_rdy_n     : out  std_logic                                           ;-- IPIC WR LLink
        ip2bus_mstwr_src_dsc_n     : out  std_logic                                           ;-- IPIC WR LLink    
        bus2ip_mstwr_dst_rdy_n     : in   std_logic                                           ;-- IPIC WR LLink
        bus2ip_mstwr_dst_dsc_n     : in   std_logic                                            -- IPIC WR LLink
    );         
end EthernetDirectCopy_Controller;

architecture Behavioral of EthernetDirectCopy_Controller is
    type m_state_labels is (    IDLE,
                                WRITE_BURST,
                                WRITE_WAIT_FOR_COMPLETE,
                                INCREMENT_ADDR,
                                HOLD,
                                WRITE_SINGLE,
                                ERROR);

    type a_state_labels is (    IDLE,
                                BURST_SOF,
                                BURST_WRITE_DATA,
                                BURST_EOF,
                                SINGLE_SOF_EOF);

    signal m_current_state, m_next_state : m_state_labels;
    signal a_current_state, a_next_state : a_state_labels;
    signal mst_type, mstwr_req, mstwr_src_rdy_n, mstwr_eof_n : std_logic;
    signal completed_transactions, mst_length : std_logic_vector(C_LENGTH_WIDTH-1 downto 0);
    signal mst_addr : std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);

begin

-----------------------------------------------------------
-- Main State-Machine
-----------------------------------------------------------
 SYNC_PROC : process (clk)
 begin
    if rising_edge(clk) then
       if resetn = '0' then
          m_current_state <= IDLE;
       else
          m_current_state <= m_next_state;
       end if;
    end if;
 end process;

 STATE_DECODE: process (m_current_state, fifo_AlmostFull, bus2ip_mst_cmdack, bus2ip_mst_cmplt, 
                        bus2ip_mst_error, fifo_Empty, MII_dv)
 begin
    --declare default state 
    m_next_state <= m_current_state;
    case (m_current_state) is
      when IDLE =>
        if fifo_AlmostFull = '1' and enable = '1' then
            m_next_state <= WRITE_BURST;
        end if;  
      when WRITE_BURST =>
        if bus2ip_mst_cmdack = '1' then
            m_next_state <= WRITE_WAIT_FOR_COMPLETE;
        end if;
      when WRITE_WAIT_FOR_COMPLETE =>
        if bus2ip_mst_cmplt = '1' then
            if bus2ip_mst_error = '0' then
                m_next_state <= INCREMENT_ADDR;
            else 
                m_next_state <= ERROR;
            end if;
        end if;
      when INCREMENT_ADDR =>
        m_next_state <= HOLD;
      when HOLD =>
        if fifo_AlmostFull = '1' then
            m_next_state <= WRITE_BURST;
        elsif MII_dv = '0' then
            if fifo_Empty = '0' then
                m_next_state <= WRITE_BURST;
            else
                m_next_state <= IDLE;
            end if;
        end if;
      when WRITE_SINGLE =>
        if bus2ip_mst_cmdack = '1' then
            m_next_state <= WRITE_WAIT_FOR_COMPLETE;
        end if;
      when ERROR =>
          m_next_state <= IDLE;
      when others =>
          m_next_state <= IDLE;
    end case;
 end process;    

 OUTPUT_DECODE: process (m_current_state)
 begin
    -- default outputs
    mstwr_req <= '0';
    ip2bus_mst_reset <= '0';
    mst_type <= '0';
    case (m_current_state) is
      when IDLE =>
      when WRITE_BURST =>
        mstwr_req <= '1';
        mst_type <= '1';
      when WRITE_WAIT_FOR_COMPLETE =>
      when HOLD =>
      when WRITE_SINGLE =>
        mstwr_req <= '1';
      when ERROR =>
        ip2bus_mst_reset <= '1';
      when others =>
    end case;
 end process; 

    ip2bus_mst_type <= mst_type;
    ip2bus_mstwr_req <= mstwr_req;

--  Generate transaction address and length
 GEN_ADDR : process (clk)
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                mst_addr <= (others => '0');
                mst_length <= std_logic_vector(to_unsigned(C_AXI_BURST_LEN,mst_length'length)); 
            else
                -- default assignment
                case (m_current_state) is
                  when IDLE =>
                    mst_addr <= initial_addr;
                    mst_length <= std_logic_vector(to_unsigned(C_AXI_BURST_LEN,mst_length'length));
                  when INCREMENT_ADDR =>
                    mst_addr <= std_logic_vector(unsigned(mst_addr) + unsigned(mst_length));
                  when HOLD =>
                    --if MII_dv = '1' then
                        mst_length <= std_logic_vector(to_unsigned(C_AXI_BURST_LEN,mst_length'length));
                    --else
                    --    mst_length <= std_logic_vector(to_unsigned(4,mst_length'length));
                    --end if;
                  when others =>
                    mst_addr <= mst_addr;
                    mst_length <= mst_length; 
                end case;
            end if;
        end if;
    end process;    
    
-----------------------------------------------------------
-- Axi State-Machine
-----------------------------------------------------------

  ASYNC_PROC : process (clk)
 begin
    if rising_edge(clk) then
       if resetn = '0' then
          a_current_state <= IDLE;
          completed_transactions <= (others => '0');
       else
          a_current_state <= a_next_state;
          -- count number of transactions
          if a_current_state = IDLE then
            completed_transactions <= (others => '0');
          elsif bus2ip_mstwr_dst_rdy_n = '0' then
            completed_transactions <= std_logic_vector(unsigned(completed_transactions) + 4);
          else
            completed_transactions <= completed_transactions;
          end if;
       end if;
    end if;
 end process;

 ASTATE_DECODE: process (a_current_state, mstwr_req, mst_type, bus2ip_mstwr_dst_rdy_n, bus2ip_mstwr_dst_dsc_n,
                        completed_transactions)
 begin
    --declare default state 
    a_next_state <= a_current_state; 
    case (a_current_state) is
      when IDLE =>
        if mstwr_req = '1' then
            if mst_type = '1' then
                a_next_state <= BURST_SOF;
            else
                a_next_state <= SINGLE_SOF_EOF;
            end if;
        end if;
      when BURST_SOF =>
        if bus2ip_mstwr_dst_rdy_n = '0' then
            a_next_state <= BURST_WRITE_DATA;
        end if;
      when BURST_WRITE_DATA =>
        if bus2ip_mstwr_dst_dsc_n = '0' then
            a_next_state <= BURST_EOF;
        else
            if bus2ip_mstwr_dst_rdy_n = '0' then
                if completed_transactions = std_logic_vector(to_unsigned(C_AXI_BURST_LEN-8,completed_transactions'length)) then
                    a_next_state <= BURST_EOF;
                 end if;
            end if;
        end if;
      when BURST_EOF =>
            if bus2ip_mstwr_dst_rdy_n = '0' then
                a_next_state <= IDLE;
            end if;
      when SINGLE_SOF_EOF =>
        if bus2ip_mstwr_dst_rdy_n = '0' then
            a_next_state <= IDLE;
        end if;
      when others =>
          a_next_state <= IDLE;
    end case;
 end process;    

 AOUTPUT_DECODE: process (a_current_state)
 begin
    -- default outputs
    ip2bus_mstwr_sof_n <= '1';
    mstwr_eof_n <= '1';
    mstwr_src_rdy_n <= '0';
    case (a_current_state) is
      when IDLE =>
        mstwr_src_rdy_n <= '1';
      when BURST_SOF =>
        ip2bus_mstwr_sof_n <= '0';
      when BURST_EOF =>
        mstwr_eof_n <= '0';    
      when SINGLE_SOF_EOF =>
        ip2bus_mstwr_sof_n <= '0';
        mstwr_eof_n <= '0';  
      when others =>
    end case;
 end process; 
 
    ip2bus_mstwr_src_rdy_n <= mstwr_src_rdy_n;
    ip2bus_mst_length <= mst_length;
    ip2bus_mst_addr <= mst_addr;
    ip2bus_mstwr_eof_n <= mstwr_eof_n; 
    fifo_RdEn <= not fifo_Empty and
                 ((bus2ip_mst_cmdack and mstwr_req) or
                 ( not(mstwr_src_rdy_n or bus2ip_mstwr_dst_rdy_n) and mstwr_eof_n));
     
-- Assign signals
    ip2bus_mstwr_d <= fifo_Dout;
    ip2bus_mst_be <= (others => '1');
    ip2bus_mstwr_src_dsc_n <= '1'; -- not supported, must be tied to 1
    ip2bus_mstwr_rem <= (others => '0');
    

    
end Behavioral;
