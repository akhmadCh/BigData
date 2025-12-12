from flask import Flask, render_template, request, redirect, url_for, flash
from minio import Minio
import sqlite3
import os
from datetime import datetime
from minio.error import S3Error
import io

app = Flask(__name__)
app.secret_key = 'super_secret_key'

# konfigurasi MinIO
minio_client = Minio(
   "localhost:9000",
   access_key="admin",
   secret_key="password123",
   secure=False
)

BUCKET_NAME = "gallery-tugas"

# konfig DB sqlite3
def init_db():
   conn = sqlite3.connect('metadata.db')
   c = conn.cursor()
   
   c.execute('''
         CREATE TABLE IF NOT EXISTS images (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            object_key TEXT NOT NULL,
            filename TEXT NOT NULL,
            mime_type TEXT,
            size INTEGER,
            title TEXT,
            description TEXT,
            tags TEXT,
            uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
         )
      ''')
   conn.commit()
   conn.close()

init_db()

@app.route('/', methods=['GET'])
def index():
   query = request.args.get('q')
   conn = sqlite3.connect('metadata.db')
   conn.row_factory = sqlite3.Row
   c = conn.cursor()
   
   if query:
      # mencari berdasarkan title, description, atau tags
      sql = """
         SELECT * FROM images 
         WHERE title LIKE ? OR description LIKE ? OR tags LIKE ?
         ORDER BY uploaded_at DESC
      """
      search_term = f"%{query}%"
      images = c.execute(sql, (search_term, search_term, search_term)).fetchall()
      
   else:
      images = c.execute("SELECT * FROM images ORDER BY uploaded_at DESC").fetchall()
   
   conn.close()
   
   # generate URL agar foto tampil
   image_list = []
   for img in images:
      url = f"http://127.0.0.1:9000/{BUCKET_NAME}/{img['object_key']}"
      
      # metadata
      data = {
         'title': img['title'],
         'description': img['description'],
         'filename': img['filename'],
         'size': img['size'],
         'tags': img['tags'],
         'url': url 
      }
      
      image_list.append(data)
      
   return render_template('index.html', images=image_list, search_query=query)

@app.route('/upload', methods=['POST'])
def upload():
   if 'file' not in request.files:
      flash('No file part')
      return redirect(request.url)
   
   file = request.files['file']
   title = request.form.get('title')
   description = request.form.get('description')
   tags = request.form.get('tags') # string koma: "alam, gunung, liburan"

   if file.filename == '':
      flash('No selected file')
      return redirect(request.url)

   if file:
      size = os.fstat(file.fileno()).st_size
      content_type = file.content_type
      # membuat object key unik
      object_key = f"{datetime.now().strftime('%Y%m%d%H%M%S')}_{file.filename}"

      try:
         # upload ke MinIO
         minio_client.put_object(
            BUCKET_NAME,
            object_key,
            file,
            size,
            content_type=content_type
         )

         conn = sqlite3.connect('metadata.db')
         c = conn.cursor()
         c.execute('''
            INSERT INTO images (object_key, filename, mime_type, size, title, description, tags)
            VALUES (?, ?, ?, ?, ?, ?, ?)
         ''', (object_key, file.filename, content_type, size, title, description, tags))
         conn.commit()
         conn.close()

         flash('File berhasil diupload!')
      except S3Error as e:
         flash(f"MinIO Error: {e}")
      except Exception as e:
         flash(f"Error: {e}")

   return redirect(url_for('index'))

if __name__ == '__main__':
   app.run(debug=True, port=5000)