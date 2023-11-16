import 'dart:io';
import 'package:campbelldecor/api/pdf_api.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../models/invoice.dart';
import '../models/supplier.dart';
import '../reusable/reusable_methods.dart';
import '../utils/invoice_util.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/widgets.dart';

class PdfInvoiceApi {
  static Future<File> generate(
      Invoice invoice, String bookingId, double total) async {
    final pdf = Document();

    pdf.addPage(MultiPage(
      build: (context) => [
        buildHeader(invoice),
        SizedBox(height: 3 * PdfPageFormat.cm),
        buildTitle(invoice),
        buildInvoice(invoice),
        Divider(color: PdfColors.green900),
        buildTotal(invoice, total),
      ],
      footer: (context) => buildFooter(invoice),
    ));

    return PdfApi.saveDocument(
        name: 'my_invoice.pdf', bookingId: bookingId, pdf: pdf);
  }

  static Widget buildHeader(Invoice invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 1 * PdfPageFormat.cm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            buildSupplierAddress(invoice.supplier),
            // Container(
            //   height: 50,
            //   width: 50,
            //   child: BarcodeWidget(
            //     barcode: Barcode.qrCode(),
            //     data: invoice.info.number,
            //   ),
            // ),
            Container(height: 150, width: 150, child: invoice.image),
          ],
        ),
        SizedBox(height: 1 * PdfPageFormat.cm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            buildCustomerAddress(invoice.customer),
            buildInvoiceInfo(invoice.info),
          ],
        ),
      ],
    );
  }

  static Widget buildCustomerAddress(Customer customer) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(customer.name, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(customer.address),
        ],
      );

  static Widget buildInvoiceInfo(InvoiceInfo info) {
    final titles = <String>[
      'Invoice Number:',
      'Invoice Date:',
    ];
    final data = <String>[
      info.number,
      Utils.formatDate(info.date),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(titles.length, (index) {
        final title = titles[index];
        final value = data[index];

        return buildText(title: title, value: value, width: 200);
      }),
    );
  }

  static Widget buildSupplierAddress(Supplier supplier) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              decoration: BoxDecoration(color: PdfColors.green900),
              child: Padding(
                padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Text(supplier.name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: PdfColors.white)),
              )),
          SizedBox(height: 1 * PdfPageFormat.mm),
          Text(supplier.address),
          SizedBox(height: 1 * PdfPageFormat.mm),
          Text(supplier.phone),
          SizedBox(height: 1 * PdfPageFormat.mm),
          Text(supplier.email),
        ],
      );

  static Widget buildTitle(Invoice invoice) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INVOICE',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 0.8 * PdfPageFormat.cm),
          Text(invoice.info.description),
          SizedBox(height: 0.8 * PdfPageFormat.cm),
        ],
      );

  static Widget buildInvoice(Invoice invoice) {
    final headers = ['Description', 'Date', 'Total amount'];
    final data = invoice.items.map((item) {
      return [
        item.description,
        Utils.formatDate(item.eventDate),
        '\$ ${item.amount}',
      ];
    }).toList();

    // data.add(['Extra Row', Utils.formatDate(DateTime.now()), '\$ 100']); // for sample

    return Table.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle:
          TextStyle(fontWeight: FontWeight.bold, color: PdfColors.white),
      headerDecoration: BoxDecoration(color: PdfColors.green900),
      cellHeight: 30,
      cellAlignments: {
        0: Alignment.centerLeft,
        1: Alignment.centerRight,
        2: Alignment.centerRight,
      },
    );
  }

  static Widget buildTotal(Invoice invoice, double total) {
    return Container(
      alignment: Alignment.centerRight,
      child: Row(
        children: [
          Spacer(flex: 6),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildText(
                  title: 'Total amount',
                  titleStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  value: Utils.formatPrice(total),
                  unite: true,
                ),
                SizedBox(height: 2 * PdfPageFormat.mm),
                Container(height: 1, color: PdfColors.grey400),
                SizedBox(height: 0.5 * PdfPageFormat.mm),
                Container(height: 1, color: PdfColors.grey400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildFooter(Invoice invoice) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Divider(color: PdfColors.green900),
          SizedBox(height: 2 * PdfPageFormat.mm),
          buildSimpleText(title: 'Address', value: ''),
          buildSimpleText(title: '', value: invoice.supplier.address),
          SizedBox(height: 1 * PdfPageFormat.mm),
          buildSimpleText(title: 'Paypal', value: invoice.supplier.paymentInfo),
        ],
      );

  static buildSimpleText({
    required String title,
    required String value,
  }) {
    final style = TextStyle(fontWeight: FontWeight.bold);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, style: style),
        SizedBox(width: 2 * PdfPageFormat.mm),
        Text(
          value,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  static buildText({
    required String title,
    required String value,
    double width = double.infinity,
    TextStyle? titleStyle,
    bool unite = false,
  }) {
    final style = titleStyle ?? TextStyle(fontWeight: FontWeight.bold);

    return Container(
      width: width,
      child: Row(
        children: [
          Expanded(child: Text(title, style: style)),
          Text(value, style: unite ? style : null),
        ],
      ),
    );
  }
}
