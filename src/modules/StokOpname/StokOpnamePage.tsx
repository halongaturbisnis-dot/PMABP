import React, { useState, useEffect, useCallback } from 'react';
import { IStokOpname } from '../../logic/types/ITs_StokOpname';
import { stokOpnameService } from '../../logic/services/stokOpnameService';
import { MainShell } from '../../ui/components/common/shells/MainShell';
import { Table, TableHeader, TableBody, TableHead, TableRow, TableCell } from '../../ui/components/common/Table';
import { Pagination } from '../../ui/components/common/Pagination';
import { SearchInput } from '../../ui/components/elements/Inputs';
import { DateRangePicker } from '../../ui/components/elements/DateRangePicker';
import { DateRange } from 'react-day-picker';
import { format } from 'date-fns';
import { PrimaryButton } from '../../ui/components/elements/Button';
import { Skeleton } from '../../ui/components/elements/Skeleton';
import { StokOpnameFormModal } from './StokOpnameFormModal';
import { StokOpnameDetailModal } from './StokOpnameDetailModal';
import { useDebounce } from '../../logic/hooks/useDebounce';
import { cn } from '../../logic/utils/cn';
import { useGlobalState } from '../../logic/context/GlobalContext';
import { formatDate } from '../../logic/utils/date';
import { History, Plus } from 'lucide-react';

export const StokOpnamePage = () => {
  const { state } = useGlobalState();
  const { isMobile } = state.viewport;

  const [data, setData] = useState<IStokOpname[]>([]);
  const [loading, setLoading] = useState(true);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [dateRange, setDateRange] = useState<DateRange | undefined>(undefined);
  const limit = 15;
  const debouncedSearch = useDebounce(search, 500);

  const [isFormOpen, setIsFormOpen] = useState(false);
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      await stokOpnameService.initTable(); // Initialize table just in case
      const res = await stokOpnameService.getPaginated(
        page, 
        limit, 
        debouncedSearch,
        dateRange?.from ? format(dateRange.from, 'yyyy-MM-dd') : undefined,
        dateRange?.to ? format(dateRange.to, 'yyyy-MM-dd') : undefined
      );
      setData(res.items);
      setTotal(res.total);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }, [page, limit, debouncedSearch, dateRange]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const handleDateRangeChange = (range: DateRange | undefined) => {
    setDateRange(range);
    setSearch(''); // Reset search input on date range change
    setPage(1);
  };

  useEffect(() => {
    setPage(1);
  }, [debouncedSearch, dateRange]);

  return (
    <MainShell 
      title="Stok Opname" 
      subtitle="Penyesuaian dan audit stok persediaan fisik dengan sistem."
      onSearchChange={(val) => setSearch(val)}
      hideDownload={true}
      hideHeaderDivider={true}
      id="stok-opname-main-page"
    >
      <div className="w-full space-y-[1.25rem]">
        <div className={cn("flex items-center justify-between gap-3", isMobile && "flex-col items-stretch")}>
          <div className={cn(isMobile ? "w-full" : "w-1/3 flex-shrink-0")}>
            <SearchInput 
              id="stok-opname-search-input"
              value={search}
              onSearch={(val) => setSearch(val)}
              placeholder="Cari SKU, Nama Produk, atau Notes..."
              className="bg-ColorBg !rounded-RadiusMedium !border-ColorPrimary/25 hover:!border-ColorPrimary focus:!border-ColorPrimary focus-visible:!border-ColorPrimary focus:!ring-0 focus-visible:!ring-0 transition-all shadow-sm"
            />
          </div>
          
          <div className={cn("flex items-center gap-SpacingSmall", isMobile ? "flex-col items-stretch gap-2" : "ml-auto flex-shrink-0")}>
            <div className={cn(isMobile ? "w-full" : "w-64")}>
              <DateRangePicker
                date={dateRange}
                onDateChange={handleDateRangeChange}
                placeholder="Filter Tanggal..."
                className="w-full"
              />
            </div>

            <PrimaryButton
              id="stok-opname-tambah-btn"
              onClick={() => {
                setIsFormOpen(true);
              }}
              icon={<Plus size={16} />}
              className="!rounded-RadiusMedium w-full sm:w-auto"
            >
              Pencatatan Stok Opname
            </PrimaryButton>
          </div>
        </div>

        <Table id="stok-opname-table" noBorder={true}>
          <TableHeader>
            <TableRow noBorder={true} isHeader={true}>
              <TableHead>Waktu Pencatatan</TableHead>
              <TableHead>SKU</TableHead>
              <TableHead>Nama Produk</TableHead>
              <TableHead>Stok Sistem</TableHead>
              <TableHead>Stok Aktual</TableHead>
              <TableHead>Selisih</TableHead>
              <TableHead>Keterangan</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {loading ? (
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
                const isPositive = row.qty_diff > 0;
                const isNegative = row.qty_diff < 0;

                return (
                  <TableRow 
                    key={row.id} 
                    noBorder={true} 
                    className="cursor-pointer select-none group hover:bg-[#f8fafc] transition-colors"
                    onClick={() => setSelectedId(row.id)}
                  >
                    <TableCell noBorder={true} className="!text-left px-[1rem]">
                      <div className="flex flex-col">
                        <span className="text-[0.875rem] font-bold text-[#1e3a34]">{formatDate(row.created_at || '')}</span>
                        <span className="text-[0.7rem] text-[#64748b]">{row.created_at?.split(/[ T]/)[1]?.slice(0, 5) || ''}</span>
                      </div>
                    </TableCell>
                    <TableCell noBorder={true} className="!text-left px-[1rem]">
                      <span className="text-[0.875rem] font-bold text-[#1e293b] ">
                        {row.sku}
                      </span>
                    </TableCell>
                    <TableCell noBorder={true} className="!text-left px-[1rem]">
                      <div className="flex flex-col">
                        <span className="text-[0.875rem] font-bold text-[#1e293b] leading-tight-normal">
                          {row.stok_name || 'Item tidak ditemukan'}
                        </span>
                      </div>
                    </TableCell>
                    <TableCell noBorder={true} className="!text-left px-[1rem]">
                      <span className="text-[0.875rem] text-[#64748b] font-medium">
                        {row.qty_system} <span className="text-[0.7rem] text-[#94a3b8]">{row.stok_unit}</span>
                      </span>
                    </TableCell>
                    <TableCell noBorder={true} className="!text-left px-[1rem]">
                      <span className="text-[0.875rem] font-bold text-[#1e293b]">
                        {row.qty_actual} <span className="text-[0.7rem] text-[#94a3b8] font-normal">{row.stok_unit}</span>
                      </span>
                    </TableCell>
                    <TableCell noBorder={true} className="!text-left px-[1rem]">
                      <span className={cn(
                        "inline-flex items-center px-[0.5rem] py-[0.125rem] rounded text-[0.75rem] font-bold",
                        isPositive ? "bg-[#dcfce7] text-[#166534]" : 
                        isNegative ? "bg-[#fee2e2] text-[#b91c1c]" : 
                        "bg-[#f1f5f9] text-[#64748b]"
                      )}>
                        {isPositive ? '+' : ''}{row.qty_diff}
                      </span>
                    </TableCell>
                    <TableCell noBorder={true} className="!text-left px-[1rem]">
                      <span className="text-[0.875rem] text-[#64748b] line-clamp-1 max-w-[15rem]">
                        {row.notes || '-'}
                      </span>
                    </TableCell>
                  </TableRow>
                );
              })
            ) : (
              <TableRow noBorder={true}>
                <TableCell colSpan={7} noBorder={true} className="h-[12rem] text-[#64748b] italic text-center">
                  <div className="flex flex-col items-center justify-center gap-[0.5rem] opacity-60">
                    <History size={48} className="text-[#cbd5e1]" />
                    <p>Belum ada pencatatan Stok Opname.</p>
                  </div>
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>

        <Pagination
          currentPage={page}
          totalPages={Math.ceil(total / limit) || 1}
          totalItems={total}
          perPage={limit}
          onPageChange={(p) => setPage(p)}
          className="mt-[1.5rem]"
          id="stok-opname-pagination"
        />

        {isFormOpen && (
          <StokOpnameFormModal 
            isOpen={isFormOpen}
            onClose={() => setIsFormOpen(false)}
            onSuccess={() => {
              loadData();
            }}
          />
        )}

        {selectedId && (
          <StokOpnameDetailModal 
            id={selectedId}
            isOpen={!!selectedId}
            onClose={() => setSelectedId(null)}
          />
        )}
      </div>
    </MainShell>
  );
};

export default StokOpnamePage;
