import streamlit as st
import pandas as pd
import numpy as np
import time

st.set_page_config(
   page_title="Dashboard FIFA World Cup",
   page_icon="🌍⚽📊",
   layout='wide',
   initial_sidebar_state='expanded'
)

@st.cache_data
def load_data(file_path):
   try:
      return pd.read_csv(file_path)
   except FileNotFoundError:
      st.error(f"File tidak ditemukan: {file_path}. Pastikan file ada di folder yang sama dengan app.py")
      return None


# load data
df_q1 = load_data('./data/data_q1_evolusi_gol.csv')
df_q2 = load_data('./data/data_q2_gol_vs_penonton.csv')
df_q3 = load_data('./data/data_q3_home_advantage.csv')
df_xg = load_data('./data/data_xg_modern.csv')


# HALAMAN UTAMA (MAIN PAGE)
st.title(':rainbow[Dashboard Analisis FIFA World Cup (1930-2022)] 🏆⚽🌍')
st.markdown("---")

filter_col1, filter_col2 = st.columns([1, 2])

with filter_col1:
   # filter 1 = tim
   if df_xg is not None:
      all_teams = sorted(df_xg['team'].unique())
      selected_teams = st.multiselect( # Ganti st.sidebar.multiselect -> st.multiselect
         'Pilih Tim (untuk Analisis xG Era Modern):',
         options=all_teams,
         default=['Argentina', 'France', 'Brazil', 'Germany', 'England']
      )
   else:
      selected_teams = []
      st.warning("Data tim tidak tersedia.")

with filter_col2:
   # filter 2 = rentang tahun tiap edisi
   if df_q1 is not None:
      year_range = st.slider(
         'Pilih Rentang Tahun:',
         min_value=int(df_q1['year'].min()),
         max_value=int(df_q1['year'].max()),
         value=(int(df_q1['year'].min()), int(df_q1['year'].max()))
      )
   else:
      year_range = (1930, 2022)
      st.warning("Data tahun tidak tersedia.")

st.markdown("---")

# logika filter
if df_q1 is not None:
   df_q1_filtered = df_q1[(df_q1['year'] >= year_range[0]) & (df_q1['year'] <= year_range[1])]
else:
   df_q1_filtered = pd.DataFrame() # Kosongkan

if df_q2 is not None:
   df_q2_filtered = df_q2[(df_q2['year'] >= year_range[0]) & (df_q2['year'] <= year_range[1])]
else:
   df_q2_filtered = pd.DataFrame() # Kosongkan

# Terapkan filter tim
if df_xg is not None:
   df_xg_filtered = df_xg[df_xg['team'].isin(selected_teams)]
else:
   df_xg_filtered = pd.DataFrame()

# ---------------------------------
# 1. KPI / METRIC ROW (Ini adalah bagian "Trendy")
# ---------------------------------
st.header('📊 Statistik Utama Turnamen')

# Hitung KPI dari data yang sudah di-load
if not df_q1_filtered.empty and not df_q2_filtered.empty and df_q3 is not None:
   avg_goals = df_q1_filtered['total_goals'].mean()
   peak_goals_row = df_q1_filtered.loc[df_q1_filtered['total_goals'].idxmax()]
   avg_attendance = df_q2_filtered['attendance_avg'].mean()
   home_adv_perc = (df_q3.loc[0, 'Win Percentage'] - df_q3.loc[1, 'Win Percentage']) * 100

   col1, col2, col3, col4 = st.columns(4)
   col1.metric("Rata-rata Gol / Laga", f"{avg_goals:.2f} ⚽")
   col2.metric(f"Puncak Gol (Tahun {int(peak_goals_row['year'])})", f"{peak_goals_row['total_goals']:.2f} 🥅")
   col3.metric("Rata-rata Penonton / Laga", f"{int(avg_attendance/1000)}K 👥")
   col4.metric("Keuntungan Tuan Rumah", f"+{home_adv_perc:.1f}% 🏠")
else:
   st.warning("Data tidak dapat dimuat untuk menampilkan KPI.")

st.markdown("---")

# 2. TABS UNTUK 3 PERTANYAAN ANALITIS (Ini adalah bagian "Terstruktur")

tab1, tab2, tab3, tab4 = st.tabs([
   "Evolusi Gaya Bermain", 
   "Gol vs Popularitas", 
   "Mitos Tuan Rumah",
   "Analisis xG (2018-2022)"
])

# --- TAB 1: Evolusi Gol ---
with tab1:
   st.subheader("Cerita dari Tiap Edisi Piala Dunia")
   
   if not df_q1_filtered.empty:
      # GANTI KODE ANIMASI DENGAN INI. LEBIH CEPAT DAN INTERAKTIF.
      st.line_chart(df_q1_filtered.rename(columns={'year':'index'}).set_index('index'))
      
      st.markdown(f"**Anomali Terdeteksi:** Puncak gol terjadi pada tahun **{int(peak_goals_row['year'])}** dengan rata-rata **{peak_goals_row['total_goals']:.2f} gol** per laga. Setelah itu, tren menurun dan stabil di era modern, menunjukkan pergeseran ke taktik yang lebih defensif.")
   
      # Ambil Top 10 dari notebook EDA Anda
      with st.expander("10 Turnamen dengan Gol Tertinggi"):
            top_10_goals_chart = df_q1_filtered.nlargest(10, 'total_goals').set_index('year')
            st.bar_chart(top_10_goals_chart)
   else:
      st.warning("Data Q1 tidak tersedia.")

# --- TAB 2: Gol vs. Popularitas ---
with tab2:
   st.subheader("Tren Popularitas Piala Dunia")
   
   if not df_q2_filtered.empty:
      # Gunakan st.scatter_chart
      st.scatter_chart(df_q2_filtered, x='total_goals', y='attendance_avg', color='year')
      
      # Hitung Korelasi
      corr = df_q2_filtered['total_goals'].corr(df_q2_filtered['attendance_avg'])
   else:
      st.warning("Data Q2 tidak tersedia.")

# --- TAB 3: Home Advantage ---
with tab3:
   st.subheader("Statistik Tuan Rumah")
   
   if df_q3 is not None:
      # Gunakan st.bar_chart
      st.bar_chart(df_q3.set_index('Category'))
   else:
      st.warning("Data Q3 tidak tersedia.")

# --- TAB 4: Bonus xG ---
with tab4:
   st.subheader("Performa vs. Expected Goals (xG) di Era Modern")
   st.write(f"Filter untuk tim: **{', '.join(selected_teams)}**")
   
   if not df_xg_filtered.empty:
      col_xg1, col_xg2 = st.columns(2)
      
      with col_xg1:
         st.write("Performance (Total Gol - Total xG)")
         # Tampilkan tim Overperformer dan Underperformer
         df_xg_perf = df_xg_filtered[['team', 'performance_vs_xg']].set_index('team').sort_values(by='performance_vs_xg', ascending=False)
         st.bar_chart(df_xg_perf)
      
      with col_xg2:
         st.write("Total Goals vs Total xG")
         # Tampilkan perbandingan
         df_xg_compare = df_xg_filtered[['team', 'total_goals', 'total_xg']].set_index('team')
         st.bar_chart(df_xg_compare)
            
      with st.expander("Data xG (Tabel)"):
         st.dataframe(df_xg_filtered)
   else:
      st.warning("Data xG tidak tersedia atau tidak ada tim yang dipilih.")