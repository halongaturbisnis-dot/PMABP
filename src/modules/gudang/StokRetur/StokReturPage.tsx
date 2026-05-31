import React, { useState, useEffect, useCallback } from 'react';
import { MainShell } from '../../../ui/components/common/shells/MainShell';
import { Table, TableHeader, TableBody, TableHead, TableRow, TableCell } from '../../../ui/components/common/Table';
import { Pagination } from '../../../ui/components/common/Pagination';
import { getPageFetchLimit } from '../../../logic/services/fetchingCenter';
import { stokReturService } from '../../../logic/services/stokReturService';
import { IStokRetur } from '../../../logic/types/ITs_StokRetur';
import { History, Calendar, Plus } from 'lucide-react';
import { SearchInput } from '../../../ui/components/elements/Inputs';
import { Skeleton } from '../../../ui/components/elements/Skeleton';
import { PrimaryButton } from '../../../ui/components/elements/Button';
import { cn } from '../../../logic/utils/cn';
import { useGlobalState } from '../../../logic/context/GlobalContext';
import { formatDate } from '../../../logic/utils/date';
import { formatCurrency } from '../../../logic/utils/data';
import { StokReturFormModal } from './StokReturFormModal';
import { StokReturDetailModal } from './StokReturDetailModal';

/**
 * STOK RETUR PAGE
 * Halaman utama untuk manajemen Stok Retur.
 * Menampilkan histori pengembalian barang secara terpusat.
 */
export const StokReturPage: React.FC = () => {
  const { state } = useGlobalState();
  const { isMobile } = state.viewport;
  
  const [data, setData] = useState<IStokRetur[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [page, setPage] = useState(1);
  const [totalItems, setTotalItems] = useState(0);
  const limit = getPageFetchLimit('StokReturPage') || 15;

  // Modal integration states
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isDetailModalOpen, setIsDetailModalOpen] = useState(false);
  const [selectedStokReturId, setSelectedStokReturId] = useState<string | undefined>(undefined);

  const fetchData = useCallback(async () => {
    setIsLoading(true);
    try {
      const { items, total } = await stokReturService.getPaginated(page, limit, searchTerm);
      setData(items);
      setTotalItems(total);
    } catch (err) {
      console.error(err);
    } finally {
      setIsLoading(false);
    }
  }, [searchTerm, page, limit]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  useEffect(() => {
    setPage(1);
  }, [searchTerm]);

  return (
    <MainShell 
      title="Stok Retur" 
      subtitle="Manajemen transaksi pengembalian stok barang dan sinkronisasi otomatis stok berjalan"
      onSearchChange={(val) => setSearchTerm(val)}
      hideDownload={true}
      hideHeaderDivider={true}
      id="stok-retur-main-page"
    >
      <div className="w-full space-y-[1.25rem]">
        <div className={cn("flex items-center justify-between gap-[1rem]", isMobile && "flex-col items-stretch")}>
          <div className={cn(isMobile ? "w-full" : "w-1/3")}>
            <SearchInput 
              id="stok-retur-search-input"
              value={searchTerm}
              onSearch={(val) => setSearchTerm(val)}
              placeholder="Cari SKU, Nama Produk, Kategori, atau Alasan..."
              className="bg-white !rounded-[0.75rem] !border-[#1e3a34]/25 hover:!border-[#1e3a34] focus:!border-[#1e3a34] focus-visible:!border-[#1e3a34] focus:!ring-0 focus-visible:!ring-0 transition-all shadow-sm"
            />
          </div>
          
          <PrimaryButton
            id="stok-retur-tambah-btn"
            onClick={() => {
              setIsModalOpen(true);
            }}
            icon={<Plus size={16} />}
          >
            Tambah Retur
          </PrimaryButton>
        </div>

        <Table id="stok-retur-table" noBorder={true}>
          <TableHeader>
            <TableRow noBorder={true} isHeader={true}>
              <TableHead>Waktu Pencatatan</TableHead>
              <TableHead>SKU</TableHead>
              <TableHead>Nama Produk</TableHead>
              <TableHead>Satuan</TableHead>
              <TableHead>Qty Retur</TableHead>
              <TableHead>Keterangan / Alasan</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              Array.from({ length: 5 }).map((_, idx) => (
                <TableRow key={`skeleton-${idx}`} noBorder={true}>
                  <TableCell noBorder={true}><Skeleton className="h-[2.5rem] w-full" /></TableCell>
                  <TableCell noBorder={true}><Skeleton className="h-[2.5rem] w-full" /></TableCell>
                  <TableCell noBorder={true}><Skeleton className="h-[2.5rem] w-full" /></TableCell>
                  <TableCell noBorder={true}><Skeleton className="h-[2.5rem] w-full" /></TableCell>
                  <TableCell noBorder={true}><Skeleton className="h-[2.5rem] w-full" /></TableCell>
                  <TableCell noBorder={true}><Skeleton className="h-[2.5rem] w-full" /></TableCell>
                </TableRow>
              ))
            ) : data.length > 0 ? (
              data.map((row) => (
                <TableRow 
                  key={row.id} 
                  noBorder={true} 
                  className="cursor-pointer select-none group hover:bg-[#f8fafc] transition-colors"
                  onClick={() => {
                    setSelectedStokReturId(row.id);
                    setIsDetailModalOpen(true);
                  }}
                >
                  <TableCell noBorder={true} className="!text-left px-[1rem]">
                    <div className="flex flex-col">
                      <span className="text-[0.875rem] font-bold text-[#1e3a34]">{formatDate(row.created_at)}</span>
                      <span className="text-[0.7rem] text-[#64748b]">{row.created_at?.split(/[ T]/)[1]?.slice(0, 5) || ''}</span>
                    </div>
                  </TableCell>
                  <TableCell noBorder={true} className="!text-left px-[1rem]">
                    <span className="text-[0.875rem] font-bold text-[#1e293b]">
                      {row.sku}
                    </span>
                  </TableCell>
                  <TableCell noBorder={true} className="!text-left px-[1rem]">
                    <div className="flex flex-col">
                      <span className="text-[0.875rem] font-bold text-[#1e293b] leading-tight-normal">
                        {row.name}
                      </span>
                      <span className="text-[#64748b] text-[0.7rem] mt-[0.25rem]">
                        {row.category}{row.sub_category ? ` > ${row.sub_category}` : ''}
                      </span>
                    </div>
                  </TableCell>
                  <TableCell noBorder={true} className="!text-left px-[1rem]">
                    <span className="text-[0.875rem] font-medium text-[#1e293b]">{row.unit || '-'}</span>
                  </TableCell>
                  <TableCell noBorder={true} className="!text-left px-[1rem]">
                    <span className="text-[0.875rem] font-bold text-[#1e293b]">
                      {row.qty}
                    </span>
                  </TableCell>
                  <TableCell noBorder={true} className="!text-left px-[1rem]">
                    <span className="text-[0.875rem] text-[#64748b] line-clamp-1 max-w-[15rem]">
                      {row.description || '-'}
                    </span>
                  </TableCell>
                </TableRow>
              ))
            ) : (
              <TableRow noBorder={true}>
                <TableCell colSpan={6} noBorder={true} className="h-[12rem] text-[#64748b] italic text-center">
                  <div className="flex flex-col items-center justify-center gap-2 opacity-60">
                    <History size={48} className="text-[#cbd5e1]" />
                    <p>Tidak ada data histori stok retur untuk ditampilkan</p>
                  </div>
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>

        <Pagination
          currentPage={page}
          totalPages={Math.ceil(totalItems / limit) || 1}
          totalItems={totalItems}
          perPage={limit}
          onPageChange={(p) => setPage(p)}
          className="mt-[1.5rem]"
          id="stok-retur-pagination"
        />

        <StokReturFormModal
          isOpen={isModalOpen}
          onClose={() => setIsModalOpen(false)}
          onSuccess={fetchData}
        />

        <StokReturDetailModal
          isOpen={isDetailModalOpen}
          onClose={() => setIsDetailModalOpen(false)}
          stokReturId={selectedStokReturId}
          onSuccess={fetchData}
        />
      </div>
    </MainShell>
  );
};

export default StokReturPage;
