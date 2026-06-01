import React, { useState, useEffect, useCallback } from 'react';
import { MainShell } from '../../../ui/components/common/shells/MainShell';
import { Table, TableHeader, TableBody, TableHead, TableRow, TableCell } from '../../../ui/components/common/Table';
import { Pagination } from '../../../ui/components/common/Pagination';
import { DateRangePicker } from '../../../ui/components/elements/DateRangePicker';
import { DateRange } from 'react-day-picker';
import { formatDateLocal } from '../../../logic/utils/date';
import { getPageFetchLimit } from '../../../logic/services/fetchingCenter';
import { stokTerbuangService } from '../../../logic/services/stokTerbuangService';
import { IStokTerbuang } from '../../../logic/types/ITs_StokTerbuang';
import { Trash2, History, Plus, Paperclip } from 'lucide-react';
import { SearchInput } from '../../../ui/components/elements/Inputs';
import { Skeleton } from '../../../ui/components/elements/Skeleton';
import { PrimaryButton } from '../../../ui/components/elements/Button';
import { cn } from '../../../logic/utils/cn';
import { useGlobalState } from '../../../logic/context/GlobalContext';
import { formatDate, formatDateDisplay } from '../../../logic/utils/date';
import { formatCurrency } from '../../../logic/utils/data';
import { StokTerbuangFormModal } from './StokTerbuangFormModal';
import { StokTerbuangDetailModal } from './StokTerbuangDetailModal';

/**
 * STOK TERBUANG PAGE
 * Halaman utama untuk manajemen Stok Terbuang.
 * Menampilkan histori pembuangan stok, susut, atau reject secara terpusat.
 */
export const StokTerbuangPage: React.FC = () => {
  const { state } = useGlobalState();
  const { isMobile } = state.viewport;
  
  const [data, setData] = useState<IStokTerbuang[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [page, setPage] = useState(1);
  const [totalItems, setTotalItems] = useState(0);
  const [dateRange, setDateRange] = useState<DateRange | undefined>(undefined);
  const limit = getPageFetchLimit('StokTerbuangPage') || 15;

  // Modal integration states
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isDetailModalOpen, setIsDetailModalOpen] = useState(false);
  const [selectedStokTerbuangId, setSelectedStokTerbuangId] = useState<string | undefined>(undefined);

  const fetchData = useCallback(async () => {
    setIsLoading(true);
    try {
      const startDate = dateRange?.from ? formatDateLocal(dateRange.from) : undefined;
      const endDate = dateRange?.to ? formatDateLocal(dateRange.to) : (dateRange?.from ? formatDateLocal(dateRange.from) : undefined);
      
      const { items, total } = await stokTerbuangService.getPaginated(page, limit, searchTerm, startDate, endDate);
      setData(items);
      setTotalItems(total);
    } catch (err) {
      console.error(err);
    } finally {
      setIsLoading(false);
    }
  }, [searchTerm, page, limit, dateRange]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  useEffect(() => {
    setPage(1);
  }, [searchTerm, dateRange]);

  return (
    <MainShell 
      title="Stok Terbuang" 
      subtitle="Manajemen pendataan stok terbuang (rusak, susut, kedaluwarsa) dan sinkronisasi otomatis stok berjalan"
      onSearchChange={(val) => setSearchTerm(val)}
      hideDownload={true}
      hideHeaderDivider={true}
      id="stok-terbuang-main-page"
    >
      <div className="w-full space-y-[1.25rem]">
        <div className={cn("flex items-center justify-between gap-[1rem]", isMobile && "flex-col items-stretch")}>
          <div className={cn(isMobile ? "w-full" : "w-1/3")}>
            <SearchInput 
              id="stok-terbuang-search-input"
              value={searchTerm}
              onSearch={(val) => setSearchTerm(val)}
              placeholder="Cari SKU, Nama Produk, Kategori, atau Alasan..."
              className="bg-white !rounded-[0.75rem] !border-[#1e3a34]/25 hover:!border-[#1e3a34] focus:!border-[#1e3a34] focus-visible:!border-[#1e3a34] focus:!ring-0 focus-visible:!ring-0 transition-all shadow-sm"
            />
          </div>
          
          <div className={cn("flex flex-1 items-center gap-[0.75rem]", !isMobile && "justify-end")}>
            <div className={cn(isMobile ? "w-full" : "w-auto min-w-[200px]")}>
              <DateRangePicker
                date={dateRange}
                onDateChange={setDateRange}
                placeholder="Filter Waktu Terbuang..."
                className="w-full"
              />
            </div>

            <PrimaryButton
              id="stok-terbuang-tambah-btn"
              onClick={() => {
                setIsModalOpen(true);
              }}
              icon={<Plus size={16} />}
              className="whitespace-nowrap"
            >
              Catat Discard
            </PrimaryButton>
          </div>
        </div>

        <Table id="stok-terbuang-table" noBorder={true}>
          <TableHeader>
            <TableRow noBorder={true} isHeader={true}>
              <TableHead>Waktu Pencatatan</TableHead>
              <TableHead>SKU</TableHead>
              <TableHead>Nama Produk</TableHead>
              <TableHead>Satuan</TableHead>
              <TableHead>Qty Terbuang</TableHead>
              <TableHead>Bukti Fisik</TableHead>
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
                  <TableCell noBorder={true}><Skeleton className="h-[2.5rem] w-full" /></TableCell>
                </TableRow>
              ))
            ) : data.length > 0 ? (
              data.map((row) => {
                let initialUrlCount = 0;
                try {
                  if (row.proof_url) {
                    const parsed = JSON.parse(row.proof_url);
                    if (Array.isArray(parsed)) {
                      initialUrlCount = parsed.length;
                    }
                  }
                } catch {}

                return (
                  <TableRow 
                    key={row.id} 
                    noBorder={true} 
                    className="cursor-pointer select-none group hover:bg-[#f8fafc] transition-colors"
                    onClick={() => {
                      setSelectedStokTerbuangId(row.id);
                      setIsDetailModalOpen(true);
                    }}
                  >
                    <TableCell noBorder={true} className="!text-left px-[1rem]">
                      {(() => {
                        const { date, time } = formatDateDisplay(row.created_at);
                        return (
                          <div className="flex flex-col">
                            <span className="text-[0.875rem] font-bold text-[#1e3a34]">{date}</span>
                            <span className="text-[0.7rem] text-[#64748b]">{time}</span>
                          </div>
                        );
                      })()}
                    </TableCell>
                    <TableCell noBorder={true} className="!text-left px-[1rem]">
                      <span className="text-[0.875rem] font-bold text-[#1e293b] ">
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
                      <span className="text-[0.875rem] font-bold text-red-600">
                        {row.qty}
                      </span>
                    </TableCell>
                    <TableCell noBorder={true} className="!text-left px-[1rem]">
                      {initialUrlCount > 0 ? (
                        <span className="inline-flex items-center gap-[0.25rem] text-[0.75rem] font-bold text-[#1e3a34] bg-[#f0fdf4] border border-[#dcfce7] px-[0.5rem] py-[0.125rem] rounded-full">
                          <Paperclip size={12} className="text-[#16a34a]" />
                          {initialUrlCount} File
                        </span>
                      ) : (
                        <span className="text-[#94a3b8] text-[0.75rem] italic">Tanpa bukti</span>
                      )}
                    </TableCell>
                    <TableCell noBorder={true} className="!text-left px-[1rem]">
                      <span className="text-[0.875rem] text-[#64748b] line-clamp-1 max-w-[15rem]">
                        {row.description || '-'}
                      </span>
                    </TableCell>
                  </TableRow>
                );
              })
            ) : (
              <TableRow noBorder={true}>
                <TableCell colSpan={7} noBorder={true} className="h-[12rem] text-[#64748b] italic text-center">
                  <div className="flex flex-col items-center justify-center gap-2 opacity-60">
                    <History size={48} className="text-[#cbd5e1]" />
                    <p>Tidak ada data histori stok terbuang untuk ditampilkan</p>
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
          id="stok-terbuang-pagination"
        />

        <StokTerbuangFormModal
          isOpen={isModalOpen}
          onClose={() => setIsModalOpen(false)}
          onSuccess={fetchData}
        />

        <StokTerbuangDetailModal
          isOpen={isDetailModalOpen}
          onClose={() => setIsDetailModalOpen(false)}
          stokTerbuangId={selectedStokTerbuangId}
          onSuccess={fetchData}
        />
      </div>
    </MainShell>
  );
};

export default StokTerbuangPage;
