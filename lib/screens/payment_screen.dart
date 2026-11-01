import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/pack.dart';
import '../services/auth_service.dart';
import '../services/registration_service.dart';

class PaymentScreen extends StatefulWidget {
  final String token;
  final String eventId;
  final String packId;
  final String packName;
  final PaymentType paymentType;
  final String? paymentDetails;
  final String? bizumConcept;

  const PaymentScreen({
    super.key,
    required this.token,
    required this.eventId,
    required this.packId,
    required this.packName,
    required this.paymentType,
    this.paymentDetails,
    this.bizumConcept,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _picker = ImagePicker();
  File? _proofImage;
  bool _isUploadingProof = false;

  Future<void> _pickProofImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _proofImage = File(picked.path));
  }

  Future<void> _uploadProof() async {
    final image = _proofImage;
    if (image == null) return;
    setState(() => _isUploadingProof = true);
    try {
      await RegistrationService.uploadPaymentProof(
        token: widget.token,
        eventId: widget.eventId,
        packId: widget.packId,
        imageFile: image,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ocurrió un error')));
      }
    } finally {
      if (mounted) setState(() => _isUploadingProof = false);
    }
  }

  Future<void> _openPaymentLink(String url) async {
    final trimmed = url.trim();
    final uri = Uri.tryParse(
      trimmed.contains('://') ? trimmed : 'https://$trimmed',
    );
    final launched =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pago')),
      body: AbsorbPointer(
        absorbing: _isUploadingProof,
        child: widget.paymentType == PaymentType.offline
            ? const SizedBox.shrink()
            : _buildProofPayment(context),
      ),
    );
  }

  Widget _buildProofPayment(BuildContext context) {
    final type = widget.paymentType;
    final details = widget.paymentDetails;
    final hasDetails = details != null && details.isNotEmpty;
    final concept = widget.bizumConcept;
    final hasConcept =
        type == PaymentType.bizum && concept != null && concept.isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;
    final busy = _isUploadingProof;

    final (icon, title, instructions, fallbackInstructions) = switch (type) {
      PaymentType.bizum => (
        Icons.phone_android,
        'Pagar por Bizum',
        'Envía el importe por Bizum a este número:',
        'Envía el importe por Bizum al organizador del evento.',
      ),
      PaymentType.paypal => (
        Icons.account_balance_wallet,
        'Pagar por PayPal',
        'Envía el importe por PayPal a:',
        'Envía el importe por PayPal al organizador del evento.',
      ),
      PaymentType.bankTransfer => (
        Icons.account_balance,
        'Pagar por transferencia bancaria',
        'Realiza la transferencia a esta cuenta:',
        'Solicita los datos bancarios al organizador del evento.',
      ),
      PaymentType.online => (
        Icons.open_in_new,
        'Pagar en plataforma externa',
        'Completa el pago en el siguiente enlace:',
        'Solicita el enlace de pago al organizador del evento.',
      ),
      PaymentType.offline => (Icons.money, '', '', ''),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pagar "${widget.packName}"',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          Text(hasDetails ? instructions : fallbackInstructions),
          if (hasDetails) ...[
            const SizedBox(height: 12),
            if (type == PaymentType.online)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openPaymentLink(details),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Abrir enlace de pago'),
                ),
              )
            else
              _copyBox(context, details),
          ],
          if (hasConcept) ...[
            const SizedBox(height: 16),
            const Text('Indica este concepto al hacer el Bizum:'),
            const SizedBox(height: 8),
            Text(
              concept,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Sube una captura del pago para confirmar tu plaza',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          if (_proofImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _proofImage!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            InkWell(
              onTap: busy ? null : _pickProofImage,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    const Text('Seleccionar captura'),
                  ],
                ),
              ),
            ),
          if (_proofImage != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: busy ? null : _pickProofImage,
              icon: const Icon(Icons.refresh),
              label: const Text('Cambiar captura'),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _proofImage != null && !busy ? _uploadProof : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Subir captura'),
          ),
        ],
      ),
    );
  }

  Widget _copyBox(BuildContext context, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.titleMedium),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Copiar',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Copiado')));
            },
          ),
        ],
      ),
    );
  }
}
