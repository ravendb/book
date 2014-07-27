using System;
using Raven.Client;
using Raven.Client.Document;

namespace Northwind
{
	public class DocumentStoreHolder
	{
		private readonly static Lazy<IDocumentStore> _store = new Lazy<IDocumentStore>(CreateDocumentStore);

		private static IDocumentStore CreateDocumentStore()
		{
			var documentStore = new DocumentStore
			{
				Url = "http://localhost:8080",
				DefaultDatabase = "Northwind",
			};

			documentStore.Initialize();
			return documentStore;
		}

		public static IDocumentStore Store
		{
			get { return _store.Value; }
		}
	}
}