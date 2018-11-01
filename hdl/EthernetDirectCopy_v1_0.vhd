library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
Library xpm;
use xpm.vcomponents.all;

entity EthernetDirectCopy_v1_0 is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S_AXI
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 4;

		-- Parameters of Axi Master Bus Interface M_AXI
        C_M_AXI_ADDR_WIDTH  : integer range 32 to 64    := 32;
        C_M_AXI_DATA_WIDTH  : integer range 32 to 256   := 32;
        C_ADDR_PIPE_DEPTH   : Integer range 1 to  14 :=  1;
        C_NATIVE_DATA_WIDTH : INTEGER range 32 to 128 := 32;
        C_LENGTH_WIDTH      : INTEGER range 12 to 20 := 12;
        C_FAMILY            : string := "artix7";
		C_M_AXI_TARGET_SLAVE_BASE_ADDR	: std_logic_vector	:= x"40000000";
		C_M_AXI_BURST_LEN	: Integer range 16 to  256 :=  16;
		C_M_AXI_ID_WIDTH	: integer	:= 1
	);
	port (
		-- Users to add ports here
        MII_tx_clk        : in std_logic;
        MII_rx_clk        : in std_logic;
        MII_crs           : in std_logic;
        MII_dv            : in std_logic;
        MII_rx_data       : in std_logic_vector (3 downto 0);
        MII_col           : in std_logic;
        MII_rx_er         : in std_logic;
        MII_rst_n         : in std_logic;
        MII_tx_en         : out std_logic;
        MII_tx_data       : out std_logic_vector (3 downto 0);
		-- Ports of Axi Slave Bus Interface S_AXI
		s_axi_aclk	: in std_logic;
		s_axi_aresetn	: in std_logic;
		s_axi_awaddr	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		s_axi_awprot	: in std_logic_vector(2 downto 0);
		s_axi_awvalid	: in std_logic;
		s_axi_awready	: out std_logic;
		s_axi_wdata	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		s_axi_wstrb	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		s_axi_wvalid	: in std_logic;
		s_axi_wready	: out std_logic;
		s_axi_bresp	: out std_logic_vector(1 downto 0);
		s_axi_bvalid	: out std_logic;
		s_axi_bready	: in std_logic;
		s_axi_araddr	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		s_axi_arprot	: in std_logic_vector(2 downto 0);
		s_axi_arvalid	: in std_logic;
		s_axi_arready	: out std_logic;
		s_axi_rdata	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		s_axi_rresp	: out std_logic_vector(1 downto 0);
		s_axi_rvalid	: out std_logic;
		s_axi_rready	: in std_logic;
  
  		-- Ports of Axi Master Bus Interface M_AXI
		m_axi_aclk	: in std_logic;
		m_axi_aresetn	: in std_logic;
		m_axi_awaddr	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		m_axi_awlen	: out std_logic_vector(7 downto 0);
		m_axi_awsize	: out std_logic_vector(2 downto 0);
		m_axi_awburst	: out std_logic_vector(1 downto 0);
		m_axi_awcache	: out std_logic_vector(3 downto 0);
		m_axi_awprot	: out std_logic_vector(2 downto 0);
		m_axi_awvalid	: out std_logic;
		m_axi_awready	: in std_logic;
		m_axi_wdata	: out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		m_axi_wstrb	: out std_logic_vector(C_M_AXI_DATA_WIDTH/8-1 downto 0);
		m_axi_wlast	: out std_logic;
		m_axi_wvalid	: out std_logic;
		m_axi_wready	: in std_logic;
		m_axi_bresp	: in std_logic_vector(1 downto 0);
		m_axi_bvalid	: in std_logic;
		m_axi_bready	: out std_logic;
		m_axi_araddr	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		m_axi_arlen	: out std_logic_vector(7 downto 0);
		m_axi_arsize	: out std_logic_vector(2 downto 0);
		m_axi_arburst	: out std_logic_vector(1 downto 0);
		m_axi_arcache	: out std_logic_vector(3 downto 0);
		m_axi_arprot	: out std_logic_vector(2 downto 0);
		m_axi_arvalid	: out std_logic;
		m_axi_arready	: in std_logic;
		m_axi_rdata	: in std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		m_axi_rresp	: in std_logic_vector(1 downto 0);
		m_axi_rlast	: in std_logic;
		m_axi_rvalid	: in std_logic;
		m_axi_rready	: out std_logic
	);
end EthernetDirectCopy_v1_0;

architecture arch_imp of EthernetDirectCopy_v1_0 is
    
	-- component declaration
	component EthernetDirectCopy_v1_0_S_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
		);
		port (
		enable          : out std_logic;
        initial_addr    : out  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component EthernetDirectCopy_v1_0_S_AXI;

    component axi_master_burst is
      generic (
        C_M_AXI_ADDR_WIDTH         : integer range 32 to 64    := 32;
        C_M_AXI_DATA_WIDTH         : integer range 32 to 256   := 32;
        C_MAX_BURST_LEN     : Integer range 16 to  256 :=  16;
        C_ADDR_PIPE_DEPTH   : Integer range 1 to  14 :=  1;
        C_NATIVE_DATA_WIDTH : INTEGER range 32 to 128 := 32;
        C_LENGTH_WIDTH      : INTEGER range 12 to 20 := 12;
        C_FAMILY                   : string := "artix7"
        );
      port (
        m_axi_aclk                  : in  std_logic                         ;-- AXI4
        m_axi_aresetn               : in  std_logic                         ;-- AXI4
        md_error                    : out  std_logic                        ;-- Error output discrete
        m_axi_arready               : in  std_logic                          ;-- AXI4
        m_axi_arvalid               : out std_logic                          ;-- AXI4
        m_axi_araddr                : out std_logic_vector                    -- AXI4
                                          (C_M_AXI_ADDR_WIDTH-1 downto 0)    ;-- AXI4
        m_axi_arlen                 : out std_logic_vector(7 downto 0)       ;-- AXI4
        m_axi_arsize                : out std_logic_vector(2 downto 0)       ;-- AXI4
        m_axi_arburst               : out std_logic_vector(1 downto 0)       ;-- AXI4
        m_axi_arprot                : out std_logic_vector(2 downto 0)       ;-- AXI4
        m_axi_arcache               : out std_logic_vector(3 downto 0)       ;-- AXI4                                                                              -- AXI4
        -- MMap Read Data Channel                                             -- AXI4
        m_axi_rready                : out std_logic                          ;-- AXI4
        m_axi_rvalid                : in  std_logic                          ;-- AXI4
        m_axi_rdata                 : in  std_logic_vector                    -- AXI4
                                          (C_M_AXI_DATA_WIDTH-1 downto 0)    ;-- AXI4
        m_axi_rresp                 : in  std_logic_vector(1 downto 0)       ;-- AXI4
        m_axi_rlast                 : in  std_logic                          ;-- AXI4
        -- Write Address Channel                                               -- AXI4
        m_axi_awready               : in  std_logic                          ; -- AXI4
        m_axi_awvalid               : out std_logic                          ; -- AXI4
        m_axi_awaddr                : out std_logic_vector                     -- AXI4
                                          (C_M_AXI_ADDR_WIDTH-1 downto 0)    ; -- AXI4
        m_axi_awlen                 : out std_logic_vector(7 downto 0)       ; -- AXI4
        m_axi_awsize                : out std_logic_vector(2 downto 0)       ; -- AXI4
        m_axi_awburst               : out std_logic_vector(1 downto 0)       ; -- AXI4
        m_axi_awprot                : out std_logic_vector(2 downto 0)       ; -- AXI4
        m_axi_awcache               : out std_logic_vector(3 downto 0)       ; -- AXI4                                                                               -- AXI4
        -- Write Data Channel                                                  -- AXI4
        m_axi_wready                : in  std_logic                          ; -- AXI4
        m_axi_wvalid                : out std_logic                          ; -- AXI4
        m_axi_wdata                 : out std_logic_vector                     -- AXI4
                                          (C_M_AXI_DATA_WIDTH-1 downto 0)    ; -- AXI4
        m_axi_wstrb                 : out std_logic_vector                     -- AXI4
                                          ((C_M_AXI_DATA_WIDTH/8)-1 downto 0); -- AXI4
        m_axi_wlast                 : out std_logic                          ; -- AXI4
                                                                               -- AXI4
        -- Write Response Channel                                              -- AXI4
        m_axi_bready                : out std_logic                          ; -- AXI4
        m_axi_bvalid                : in  std_logic                          ; -- AXI4
        m_axi_bresp                 : in  std_logic_vector(1 downto 0)       ; -- AXI4
        -- IPIC Request/Qualifiers
        ip2bus_mstrd_req           : In  std_logic                                           ;-- IPIC CMD
        ip2bus_mstwr_req           : In  std_logic                                           ;-- IPIC CMD
        ip2bus_mst_addr            : in  std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0)     ;-- IPIC CMD
        ip2bus_mst_length          : in  std_logic_vector(C_LENGTH_WIDTH-1 downto 0)         ;-- IPIC CMD
        ip2bus_mst_be              : in  std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);-- IPIC CMD
        ip2bus_mst_type            : in  std_logic                                           ;-- IPIC CMD
        ip2bus_mst_lock            : In  std_logic                                           ;-- IPIC CMD
        ip2bus_mst_reset           : In  std_logic                                           ;-- IPIC CMD
        -- IPIC Request Status Reply
        bus2ip_mst_cmdack          : Out std_logic                                           ;-- IPIC Stat
        bus2ip_mst_cmplt           : Out std_logic                                           ;-- IPIC Stat
        bus2ip_mst_error           : Out std_logic                                           ;-- IPIC Stat
        bus2ip_mst_rearbitrate     : Out std_logic                                           ;-- IPIC Stat
        bus2ip_mst_cmd_timeout     : out std_logic                                           ;-- IPIC Stat
        -- IPIC Read LocalLink Channel
        bus2ip_mstrd_d             : out std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0 )   ;-- IPIC RD LLink
        bus2ip_mstrd_rem           : out std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);-- IPIC RD LLink
        bus2ip_mstrd_sof_n         : Out std_logic                                           ;-- IPIC RD LLink
        bus2ip_mstrd_eof_n         : Out std_logic                                           ;-- IPIC RD LLink
        bus2ip_mstrd_src_rdy_n     : Out std_logic                                           ;-- IPIC RD LLink
        bus2ip_mstrd_src_dsc_n     : Out std_logic                                           ;-- IPIC RD LLink
        ip2bus_mstrd_dst_rdy_n     : In  std_logic                                           ;-- IPIC RD LLink
        ip2bus_mstrd_dst_dsc_n     : In  std_logic                                           ;-- IPIC RD LLink
        -- IPIC Write LocalLink Channel
        ip2bus_mstwr_d             : In  std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0)    ;-- IPIC WR LLink
        ip2bus_mstwr_rem           : In  std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);-- IPIC WR LLink
        ip2bus_mstwr_sof_n         : In  std_logic                                           ;-- IPIC WR LLink
        ip2bus_mstwr_eof_n         : In  std_logic                                           ;-- IPIC WR LLink
        ip2bus_mstwr_src_rdy_n     : In  std_logic                                           ;-- IPIC WR LLink
        ip2bus_mstwr_src_dsc_n     : In  std_logic                                           ;-- IPIC WR LLink    
        bus2ip_mstwr_dst_rdy_n     : Out std_logic                                           ;-- IPIC WR LLink
        bus2ip_mstwr_dst_dsc_n     : Out std_logic                                            -- IPIC WR LLink    
        );    
    end component axi_master_burst;

    component EthernetDirectCopy_Controller is
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
            initial_addr    : in  std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0)     ;
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
    end component EthernetDirectCopy_Controller;

    component EthernetDirectCopy_Mii2Fifo is
      Generic (
          C_FIFO_ALMOST_FULL        : integer    := 16;
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
    end component EthernetDirectCopy_Mii2Fifo;
    
    signal initial_addr : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal dv, m_enable, s_enable, mii_enable : std_logic;
    signal md_error : std_logic;
    signal fifo_RdEn, fifo_RdError, fifo_AlmostFull, fifo_Empty : std_logic;
    signal fifo_Dout : std_logic_vector(31 downto 0);
    
    signal ip2bus_mstrd_req, ip2bus_mstwr_req: std_logic ;
    signal ip2bus_mst_addr            :  std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0)     ;
    signal ip2bus_mst_length          : std_logic_vector(C_LENGTH_WIDTH-1 downto 0);-- IPIC CMD
    signal ip2bus_mst_be              : std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);-- IPIC CMD
    signal ip2bus_mst_type, ip2bus_mst_lock, ip2bus_mst_reset : std_logic; -- IPIC CMD
    -- IPIC Request Status Reply
    signal bus2ip_mst_cmdack, bus2ip_mst_cmplt, bus2ip_mst_error : std_logic;-- IPIC Stat
    signal bus2ip_mst_rearbitrate, bus2ip_mst_cmd_timeout : std_logic ;-- IPIC Stat
    -- IPIC Read LocalLink Channel
    signal bus2ip_mstrd_d             : std_logic_vector(C_NATIVE_DATA_WIDTH - 1 downto 0 ) ;-- IPIC RD LLink
    signal bus2ip_mstrd_rem           : std_logic_vector((C_NATIVE_DATA_WIDTH/8) - 1 downto 0);-- IPIC RD LLink
    signal bus2ip_mstrd_sof_n, bus2ip_mstrd_eof_n, bus2ip_mstrd_src_rdy_n : std_logic;-- IPIC RD LLink
    signal bus2ip_mstrd_src_dsc_n, ip2bus_mstrd_dst_rdy_n, ip2bus_mstrd_dst_dsc_n : std_logic;-- IPIC RD LLink
    -- IPIC Write LocalLink Channel
    signal ip2bus_mstwr_d             : std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0)    ;-- IPIC WR LLink
    signal ip2bus_mstwr_rem           : std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);-- IPIC WR LLink
    signal ip2bus_mstwr_sof_n, ip2bus_mstwr_eof_n, ip2bus_mstwr_src_rdy_n : std_logic;-- IPIC WR LLink
    signal ip2bus_mstwr_src_dsc_n, bus2ip_mstwr_dst_rdy_n, bus2ip_mstwr_dst_dsc_n : std_logic; -- IPIC WR LLink
    
      
    
begin

-- Instantiation of Axi Bus Interface S_AXI
EthernetDirectCopy_v1_0_S_AXI_inst : EthernetDirectCopy_v1_0_S_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S_AXI_ADDR_WIDTH
	)
	port map (
        enable          =>   s_enable,
        initial_addr    => initial_addr,
		S_AXI_ACLK	    => s_axi_aclk,
		S_AXI_ARESETN	=> s_axi_aresetn,
		S_AXI_AWADDR	=> s_axi_awaddr,
		S_AXI_AWPROT	=> s_axi_awprot,
		S_AXI_AWVALID	=> s_axi_awvalid,
		S_AXI_AWREADY	=> s_axi_awready,
		S_AXI_WDATA	    => s_axi_wdata,
		S_AXI_WSTRB	=> s_axi_wstrb,
		S_AXI_WVALID	=> s_axi_wvalid,
		S_AXI_WREADY	=> s_axi_wready,
		S_AXI_BRESP	=> s_axi_bresp,
		S_AXI_BVALID	=> s_axi_bvalid,
		S_AXI_BREADY	=> s_axi_bready,
		S_AXI_ARADDR	=> s_axi_araddr,
		S_AXI_ARPROT	=> s_axi_arprot,
		S_AXI_ARVALID	=> s_axi_arvalid,
		S_AXI_ARREADY	=> s_axi_arready,
		S_AXI_RDATA	=> s_axi_rdata,
		S_AXI_RRESP	=> s_axi_rresp,
		S_AXI_RVALID	=> s_axi_rvalid,
		S_AXI_RREADY	=> s_axi_rready
	);

-- Instantiation of Axi Bus Interface M_AXI
 EthernetDirectCopy_v1_0_M_AXI_inst : axi_master_burst 
  generic map (
        C_M_AXI_ADDR_WIDTH => C_M_AXI_ADDR_WIDTH,
        C_M_AXI_DATA_WIDTH => C_M_AXI_DATA_WIDTH,
        C_MAX_BURST_LEN =>  C_M_AXI_BURST_LEN,
        C_ADDR_PIPE_DEPTH  => C_ADDR_PIPE_DEPTH,
        C_NATIVE_DATA_WIDTH => C_NATIVE_DATA_WIDTH,
        C_LENGTH_WIDTH => C_LENGTH_WIDTH,
        C_FAMILY => C_FAMILY
    )
	port map (                                                                           -- AXI4
		M_AXI_ACLK	=> m_axi_aclk,
		M_AXI_ARESETN	=> m_axi_aresetn,
        md_error => md_error,   -- Error output discrete
		M_AXI_ARREADY	=> m_axi_arready,
        M_AXI_ARVALID    => m_axi_arvalid,
		M_AXI_ARADDR	=> m_axi_araddr,
        M_AXI_ARLEN    => m_axi_arlen,
        M_AXI_ARSIZE    => m_axi_arsize,
		M_AXI_ARBURST	=> m_axi_arburst,
		M_AXI_ARPROT	=> m_axi_arprot,
        M_AXI_ARCACHE    => m_axi_arcache,
    -- MMap Read Data Channel                                             -- AXI4
		M_AXI_RREADY	=> m_axi_rready,
		M_AXI_RVALID	=> m_axi_rvalid,
        M_AXI_RDATA    => m_axi_rdata,
        M_AXI_RRESP    => m_axi_rresp,
		M_AXI_RLAST	=> m_axi_rlast,
    -- Write Address Channel                                               -- AXI4
		M_AXI_AWREADY	=> m_axi_awready,
        M_AXI_AWVALID    => m_axi_awvalid,
		M_AXI_AWADDR	=> m_axi_awaddr,
        M_AXI_AWLEN    => m_axi_awlen,
        M_AXI_AWSIZE    => m_axi_awsize,
        M_AXI_AWBURST    => m_axi_awburst,
		M_AXI_AWPROT	=> m_axi_awprot,
		M_AXI_AWCACHE	=> m_axi_awcache,
        -- Write Data Channel                                                  -- AXI4
        M_AXI_WREADY	=> m_axi_wready,
        M_AXI_WVALID    => m_axi_wvalid,
        M_AXI_WDATA    => m_axi_wdata,
        M_AXI_WSTRB    => m_axi_wstrb,
        M_AXI_WLAST    => m_axi_wlast,
        -- Write Response Channel                                              -- AXI4
        M_AXI_BREADY	=> m_axi_bready,
        M_AXI_BVALID    => m_axi_bvalid,
        M_AXI_BRESP    => m_axi_bresp,
        -- IPIC Request/Qualifiers
        ip2bus_mstrd_req => ip2bus_mstrd_req,
        ip2bus_mstwr_req  => ip2bus_mstwr_req,
        ip2bus_mst_addr => ip2bus_mst_addr,
        ip2bus_mst_length => ip2bus_mst_length,
        ip2bus_mst_be => ip2bus_mst_be,
        ip2bus_mst_type  => ip2bus_mst_type,
        ip2bus_mst_lock => ip2bus_mst_lock,
        ip2bus_mst_reset => ip2bus_mst_reset,
        -- IPIC Request Status Reply
        bus2ip_mst_cmdack  => bus2ip_mst_cmdack,
        bus2ip_mst_cmplt => bus2ip_mst_cmplt,
        bus2ip_mst_error => bus2ip_mst_error,
        bus2ip_mst_rearbitrate => open,
        bus2ip_mst_cmd_timeout => open,
        -- IPIC Read LocalLink Channel
        bus2ip_mstrd_rem => bus2ip_mstrd_rem,
        bus2ip_mstrd_sof_n => bus2ip_mstrd_sof_n,
        bus2ip_mstrd_eof_n => bus2ip_mstrd_eof_n,
        bus2ip_mstrd_src_rdy_n => bus2ip_mstrd_src_rdy_n,
        bus2ip_mstrd_src_dsc_n => bus2ip_mstrd_src_dsc_n,
        ip2bus_mstrd_dst_rdy_n => ip2bus_mstrd_dst_rdy_n,
        ip2bus_mstrd_dst_dsc_n => ip2bus_mstrd_dst_dsc_n,
        -- IPIC Write LocalLink Channel
        ip2bus_mstwr_d  => ip2bus_mstwr_d,
        ip2bus_mstwr_rem => ip2bus_mstwr_rem,
        ip2bus_mstwr_sof_n => ip2bus_mstwr_sof_n,
        ip2bus_mstwr_eof_n => ip2bus_mstwr_eof_n,
        ip2bus_mstwr_src_rdy_n => ip2bus_mstwr_src_rdy_n,
        ip2bus_mstwr_src_dsc_n => ip2bus_mstwr_src_dsc_n,    
        bus2ip_mstwr_dst_rdy_n => bus2ip_mstwr_dst_rdy_n,
        bus2ip_mstwr_dst_dsc_n => bus2ip_mstwr_dst_dsc_n        
    );

    ip2bus_mstrd_req <= '0';
    ip2bus_mst_lock  <= '0';
    ip2bus_mstrd_dst_rdy_n <= '1';   
    ip2bus_mstrd_dst_dsc_n <= '1';


    EdcController_Ins : EthernetDirectCopy_Controller
        generic map(
            C_M_AXI_ADDR_WIDTH => C_M_AXI_ADDR_WIDTH,
            C_LENGTH_WIDTH => C_LENGTH_WIDTH,
            C_NATIVE_DATA_WIDTH => C_NATIVE_DATA_WIDTH,
            C_AXI_BURST_LEN	=> C_M_AXI_BURST_LEN
        )
        port map (
            clk => m_axi_aclk,
            resetn => m_axi_aresetn,
            enable => m_enable,
            fifo_RdEn => fifo_RdEn,
            fifo_RdError => fifo_RdError,
            fifo_Dout => fifo_Dout,
            fifo_AlmostFull => fifo_AlmostFull,
            fifo_Empty => fifo_Empty,                   
            MII_dv => dv,                   
            initial_addr => initial_addr,
        -- IPIC Request/Qualifiers
            ip2bus_mstwr_req  => ip2bus_mstwr_req,
            ip2bus_mst_addr => ip2bus_mst_addr,
            ip2bus_mst_length => ip2bus_mst_length,
            ip2bus_mst_be => ip2bus_mst_be,
            ip2bus_mst_type  => ip2bus_mst_type,
            ip2bus_mst_reset => ip2bus_mst_reset,
            -- IPIC Request Status Reply
            bus2ip_mst_cmdack  => bus2ip_mst_cmdack,
            bus2ip_mst_cmplt => bus2ip_mst_cmplt,
            bus2ip_mst_error => bus2ip_mst_error,
            -- IPIC Write LocalLink Channel
            ip2bus_mstwr_d  => ip2bus_mstwr_d,
            ip2bus_mstwr_rem => ip2bus_mstwr_rem,
            ip2bus_mstwr_sof_n => ip2bus_mstwr_sof_n,
            ip2bus_mstwr_eof_n => ip2bus_mstwr_eof_n,
            ip2bus_mstwr_src_rdy_n => ip2bus_mstwr_src_rdy_n,
            ip2bus_mstwr_src_dsc_n => ip2bus_mstwr_src_dsc_n,    
            bus2ip_mstwr_dst_rdy_n => bus2ip_mstwr_dst_rdy_n,
            bus2ip_mstwr_dst_dsc_n => bus2ip_mstwr_dst_dsc_n        
        );

    EdcMii2Fifo_Ins : EthernetDirectCopy_Mii2Fifo
        Generic map (
          C_FIFO_ALMOST_FULL => C_M_AXI_BURST_LEN / 4,
          C_FIFO_WIDTH  => C_NATIVE_DATA_WIDTH       
          )
        Port map ( 
            resetn => m_axi_aresetn,
            enable => mii_enable,
            MII_rx_clk => MII_rx_clk,
            MII_dv => MII_dv,
            MII_rx_data => MII_rx_data,
            MII_rx_er => MII_rx_er,
            fifo_RdClk => m_axi_aclk,
            fifo_RdEn => fifo_RdEn,
            fifo_RdError => fifo_RdError,
            fifo_Dout => fifo_Dout,
            fifo_AlmostFull => fifo_AlmostFull,
            fifo_Empty => fifo_Empty                   
            );

    -- xpm_cdc_single: Clock Domain Crossing Single-bit Synchronizer
    -- Xilinx Parameterized Macro, Version 2017.2
    xpm_cdc_dv: xpm_cdc_single
      port map (
         src_clk  => MII_rx_clk,  -- optional; required when SRC_INPUT_REG = 1
         src_in   => MII_dv,
         dest_clk => m_axi_aclk,
         dest_out => dv
      );
      
    xpm_cdc_enable1: xpm_cdc_single
      generic map ( SRC_INPUT_REG => 0)
      port map (
         src_clk  => s_axi_aclk, 
         src_in   => s_enable,
         dest_clk => m_axi_aclk,
         dest_out => m_enable
      );
      
    xpm_cdc_enable2: xpm_cdc_single
        generic map ( SRC_INPUT_REG => 0)
        port map ( 
           src_clk  => s_axi_aclk, 
           src_in   => s_enable,
           dest_clk => MII_rx_clk,
           dest_out => mii_enable
        );
      
end arch_imp;
